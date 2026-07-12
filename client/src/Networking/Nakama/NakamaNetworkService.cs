using System;
using System.Threading;
using System.Threading.Tasks;
using Aethermoor.Core.Diagnostics;
using Aethermoor.Core.Events;
using Aethermoor.Networking.Connection;
using Aethermoor.Networking.Model;
using Nakama;

namespace Aethermoor.Networking.NakamaAdapter;

/// <summary>
/// Konkrete <see cref="INetworkService"/>-Implementierung gegen das Nakama-Backend:
/// gerätebasierte Authentifizierung, Sitzungsverwaltung und Realtime-Socket mit
/// automatischem Wiederaufbau über <see cref="ReconnectBackoff"/>.
/// </summary>
/// <remarks>
/// <para>
/// Einziger Ort im Client, an dem Nakama-SDK-Typen erscheinen (ADR-0002): Nach außen
/// existieren nur <see cref="SessionInfo"/>, <see cref="ConnectionState"/> und die
/// EventBus-Ereignisse. Ein Backend-Wechsel bliebe damit auf diesen Ordner begrenzt.
/// </para>
/// <para>
/// Die Verifikation gegen den lokalen Docker-Stack (<c>server/</c>) ist Teil der
/// Milestone-3-Abnahme (siehe Networking/README.md).
/// </para>
/// </remarks>
public sealed class NakamaNetworkService : INetworkService
{
    private const string LogCategory = "Net";

    private readonly ServerEndpoint _endpoint;
    private readonly EventBus _events;
    private readonly IGameLogger _logger;
    private readonly ConnectionStateMachine _stateMachine = new();
    private readonly ReconnectBackoff _backoff;

    private Client? _client;
    private ISession? _session;
    private ISocket? _socket;
    private AuthCredentials _credentials;
    private bool _userInitiatedDisconnect;

    public NakamaNetworkService(
        ServerEndpoint endpoint,
        EventBus events,
        IGameLogger logger,
        ReconnectBackoff? backoff = null)
    {
        ArgumentNullException.ThrowIfNull(events);
        ArgumentNullException.ThrowIfNull(logger);

        _endpoint = endpoint;
        _events = events;
        _logger = logger;
        _backoff = backoff ?? new ReconnectBackoff(
            baseDelay: TimeSpan.FromSeconds(1),
            maxDelay: TimeSpan.FromSeconds(30),
            maxAttempts: 8);

        _stateMachine.Changed += OnStateChanged;
    }

    /// <inheritdoc />
    public ConnectionState State => _stateMachine.Current;

    /// <inheritdoc />
    public SessionInfo? Session { get; private set; }

    /// <inheritdoc />
    public void Initialize()
    {
        // Kein Aufbau nötig — Aktivierung erfolgt über ConnectAsync.
    }

    /// <inheritdoc />
    public void Shutdown()
    {
        _stateMachine.Changed -= OnStateChanged;
        _ = DisconnectAsync();
    }

    /// <inheritdoc />
    public async Task ConnectAsync(AuthCredentials credentials, CancellationToken cancellationToken = default)
    {
        if (State is ConnectionState.Connecting or ConnectionState.Connected)
        {
            _logger.Debug(LogCategory, "Verbindungsanfrage ignoriert — bereits verbunden oder im Aufbau.");
            return;
        }

        _credentials = credentials;
        _userInitiatedDisconnect = false;
        _stateMachine.TransitionTo(ConnectionState.Connecting);

        try
        {
            await EstablishAsync(cancellationToken).ConfigureAwait(false);
            _stateMachine.TransitionTo(ConnectionState.Connected);
            _events.Publish(new NetworkAuthenticatedEvent(Session!.UserId, Session.Username));
            _logger.Info(LogCategory, $"Verbunden mit {_endpoint.BaseUri} als '{Session.Username}'.");
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.Error(LogCategory, $"Verbindungsaufbau fehlgeschlagen: {ex.Message}");
            _stateMachine.TransitionTo(ConnectionState.Failed);
            _events.Publish(new NetworkErrorEvent($"Verbindungsaufbau fehlgeschlagen: {ex.Message}"));
        }
    }

    /// <inheritdoc />
    public async Task DisconnectAsync()
    {
        _userInitiatedDisconnect = true;

        if (_socket is not null)
        {
            try
            {
                await _socket.CloseAsync().ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                _logger.Warning(LogCategory, $"Socket-Schließen meldete: {ex.Message}");
            }

            _socket = null;
        }

        _session = null;
        Session = null;
        _stateMachine.TryTransitionTo(ConnectionState.Disconnected);
    }

    private async Task EstablishAsync(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        _client ??= new Client(_endpoint.Scheme, _endpoint.Host, _endpoint.Port, _endpoint.ServerKey);

        _session = await _client.AuthenticateDeviceAsync(
            _credentials.DeviceId, _credentials.Username, create: true,
            canceller: cancellationToken).ConfigureAwait(false);

        Session = new SessionInfo(
            UserId: _session.UserId,
            Username: _session.Username,
            AuthToken: _session.AuthToken,
            ExpiresAt: DateTimeOffset.FromUnixTimeSeconds(_session.ExpireTime));

        ISocket socket = Socket.From(_client);
        socket.Closed += OnSocketClosed;
        await socket.ConnectAsync(_session).ConfigureAwait(false);
        _socket = socket;
    }

    private void OnSocketClosed()
    {
        if (_userInitiatedDisconnect)
        {
            return; // gewollte Trennung — DisconnectAsync übernimmt die Zustandsführung
        }

        _logger.Warning(LogCategory, "Verbindung verloren — automatischer Wiederaufbau startet.");
        if (_stateMachine.TryTransitionTo(ConnectionState.Reconnecting))
        {
            _ = ReconnectLoopAsync();
        }
    }

    private async Task ReconnectLoopAsync()
    {
        for (int attempt = 1; _backoff.ShouldRetry(attempt); attempt++)
        {
            TimeSpan delay = _backoff.NextDelay(attempt);
            _logger.Info(LogCategory, $"Wiederverbindungsversuch {attempt} in {delay.TotalSeconds:F1} s.");
            await Task.Delay(delay).ConfigureAwait(false);

            if (_userInitiatedDisconnect || State != ConnectionState.Reconnecting)
            {
                return; // inzwischen getrennt oder anderweitig aufgelöst
            }

            try
            {
                await EstablishAsync(CancellationToken.None).ConfigureAwait(false);
                _stateMachine.TransitionTo(ConnectionState.Connected);
                _events.Publish(new NetworkAuthenticatedEvent(Session!.UserId, Session.Username));
                _logger.Info(LogCategory, "Wiederverbindung erfolgreich.");
                return;
            }
            catch (Exception ex)
            {
                _logger.Warning(LogCategory, $"Wiederverbindungsversuch {attempt} fehlgeschlagen: {ex.Message}");
            }
        }

        _stateMachine.TryTransitionTo(ConnectionState.Failed);
        _events.Publish(new NetworkErrorEvent("Wiederverbindung endgültig fehlgeschlagen."));
    }

    private void OnStateChanged(ConnectionStateChange change)
    {
        _logger.Debug(LogCategory, $"Verbindungszustand: {change.Previous} → {change.Current}.");
        _events.Publish(new NetworkStateChangedEvent(change.Previous, change.Current));
    }
}
