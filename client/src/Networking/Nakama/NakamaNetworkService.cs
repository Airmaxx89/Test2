using System;
using System.Collections.Concurrent;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
using Aethermoor.Core.Diagnostics;
using Aethermoor.Core.Events;
using Aethermoor.Networking.Connection;
using Aethermoor.Networking.Model;
using Aethermoor.Networking.Protocol;
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
public sealed class NakamaNetworkService : INetworkService, IMatchClient
{
    private const string LogCategory = "Net";
    private const string RpcFindOrCreateMovementMatch = "find_or_create_movement_match";

    /// <summary>Obergrenze gepufferter Snapshots (Consumer hängt/pausiert → alte verwerfen).</summary>
    private const int MaxQueuedSnapshots = 32;

    private readonly ServerEndpoint _endpoint;
    private readonly EventBus _events;
    private readonly IGameLogger _logger;
    private readonly ConnectionStateMachine _stateMachine = new();
    private readonly ReconnectBackoff _backoff;

    private readonly ConcurrentQueue<MovementSnapshot> _snapshots = new();

    private Client? _client;
    private ISession? _session;
    private ISocket? _socket;
    private IMatch? _match;
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

        _match = null;
        _snapshots.Clear();
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
        socket.ReceivedMatchState += OnReceivedMatchState;
        await socket.ConnectAsync(_session).ConfigureAwait(false);
        _socket = socket;
    }

    // ─── IMatchClient ────────────────────────────────────────────────────────

    /// <inheritdoc />
    public bool IsInMatch => _match is not null;

    /// <inheritdoc />
    public async Task JoinMovementMatchAsync(CancellationToken cancellationToken = default)
    {
        if (_client is null || _session is null || _socket is null)
        {
            throw new InvalidOperationException(
                "Match-Beitritt erfordert eine bestehende Verbindung (zuerst ConnectAsync).");
        }

        if (_match is not null)
        {
            return;
        }

        IApiRpc rpc = await _client.RpcAsync(
            _session, RpcFindOrCreateMovementMatch, canceller: cancellationToken).ConfigureAwait(false);

        MatchIdResponse? response = null;
        if (!string.IsNullOrWhiteSpace(rpc.Payload))
        {
            response = JsonSerializer.Deserialize<MatchIdResponse>(rpc.Payload);
        }

        if (string.IsNullOrEmpty(response?.MatchId))
        {
            throw new InvalidOperationException(
                $"RPC '{RpcFindOrCreateMovementMatch}' lieferte keine Match-ID.");
        }

        _match = await _socket.JoinMatchAsync(response.MatchId).ConfigureAwait(false);
        _logger.Info(LogCategory, $"Bewegungs-Match beigetreten: {_match.Id}.");
    }

    /// <inheritdoc />
    public async Task LeaveMatchAsync()
    {
        if (_match is null || _socket is null)
        {
            _match = null;
            return;
        }

        string matchId = _match.Id;
        _match = null;
        _snapshots.Clear();

        try
        {
            await _socket.LeaveMatchAsync(matchId).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            _logger.Warning(LogCategory, $"Match-Verlassen meldete: {ex.Message}");
        }
    }

    /// <inheritdoc />
    public void SendMovementInput(MovementInputPayload input)
    {
        if (_match is null || _socket is null)
        {
            return;
        }

        string json = MovementProtocol.EncodeInput(input);
        _ = SendMatchStateSafeAsync(_match.Id, MovementProtocol.OpCodeInput, json);
    }

    /// <inheritdoc />
    public bool TryDequeueSnapshot(out MovementSnapshot? snapshot)
    {
        bool dequeued = _snapshots.TryDequeue(out MovementSnapshot? result);
        snapshot = result;
        return dequeued;
    }

    private async Task SendMatchStateSafeAsync(string matchId, long opCode, string payload)
    {
        try
        {
            await _socket!.SendMatchStateAsync(matchId, opCode, payload).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            // Fire-and-forget: Der nächste Frame sendet ohnehin neu; nur protokollieren.
            _logger.Warning(LogCategory, $"Eingabe-Versand fehlgeschlagen: {ex.Message}");
        }
    }

    private void OnReceivedMatchState(IMatchState state)
    {
        if (state.OpCode != MovementProtocol.OpCodeSnapshot)
        {
            return;
        }

        string json = Encoding.UTF8.GetString(state.State);
        MovementSnapshot? snapshot = MovementProtocol.DecodeSnapshot(json);
        if (snapshot is null)
        {
            _logger.Warning(LogCategory, "Unlesbarer Snapshot verworfen.");
            return;
        }

        _snapshots.Enqueue(snapshot);
        while (_snapshots.Count > MaxQueuedSnapshots)
        {
            _snapshots.TryDequeue(out _); // Ältestes verwerfen — nur der jüngste Stand zählt.
        }
    }

    /// <summary>Antwort des Match-RPCs: <c>{"matchId": "…"}</c>.</summary>
    private sealed record MatchIdResponse(
        [property: JsonPropertyName("matchId")] string? MatchId);

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
