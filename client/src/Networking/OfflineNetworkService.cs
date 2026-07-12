using System;
using System.Threading;
using System.Threading.Tasks;
using Aethermoor.Core.Diagnostics;
using Aethermoor.Core.Events;
using Aethermoor.Networking.Connection;
using Aethermoor.Networking.Model;

namespace Aethermoor.Networking;

/// <summary>
/// SDK-freie <see cref="INetworkService"/>-Implementierung ohne echten Server: erzeugt lokal
/// eine Sitzung und durchläuft die reale <see cref="ConnectionStateMachine"/>. Sie macht die
/// Netzwerk-Abstraktion sofort nutz- und testbar und dient als Vorlage sowie Entwicklungs-
/// Stand-in, bis der Nakama-Adapter (Milestone 3, Folge-Iteration) sie ersetzt.
/// </summary>
/// <remarks>
/// Vollständig engine- und SDK-frei und damit in CI unit-getestet (ARCHITECTURE §8). Die
/// Zustandsübergänge werden als EventBus-Ereignisse veröffentlicht; das Sitzungstoken bleibt
/// intern (nicht im Ereignis).
/// </remarks>
public sealed class OfflineNetworkService : INetworkService
{
    private const string LogCategory = "Net";

    private readonly EventBus _events;
    private readonly IGameLogger _logger;
    private readonly ConnectionStateMachine _stateMachine = new();

    public OfflineNetworkService(EventBus events, IGameLogger logger)
    {
        ArgumentNullException.ThrowIfNull(events);
        ArgumentNullException.ThrowIfNull(logger);

        _events = events;
        _logger = logger;
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
        _stateMachine.TryTransitionTo(ConnectionState.Disconnected);
        Session = null;
    }

    /// <inheritdoc />
    public Task ConnectAsync(AuthCredentials credentials, CancellationToken cancellationToken = default)
    {
        if (State is ConnectionState.Connecting or ConnectionState.Connected)
        {
            _logger.Debug(LogCategory, "Verbindungsanfrage ignoriert — bereits verbunden oder im Aufbau.");
            return Task.CompletedTask;
        }

        cancellationToken.ThrowIfCancellationRequested();

        _stateMachine.TransitionTo(ConnectionState.Connecting);

        Session = new SessionInfo(
            UserId: $"offline-{credentials.DeviceId}",
            Username: credentials.Username ?? "Offline-Spieler",
            AuthToken: "offline-token",
            ExpiresAt: DateTimeOffset.UtcNow.AddHours(1));

        _stateMachine.TransitionTo(ConnectionState.Connected);
        _events.Publish(new NetworkAuthenticatedEvent(Session.UserId, Session.Username));
        _logger.Info(LogCategory, $"Offline verbunden als '{Session.Username}'.");
        return Task.CompletedTask;
    }

    /// <inheritdoc />
    public Task DisconnectAsync()
    {
        _stateMachine.TryTransitionTo(ConnectionState.Disconnected);
        Session = null;
        return Task.CompletedTask;
    }

    private void OnStateChanged(ConnectionStateChange change)
    {
        _logger.Debug(LogCategory, $"Verbindungszustand: {change.Previous} → {change.Current}.");
        _events.Publish(new NetworkStateChangedEvent(change.Previous, change.Current));
    }
}
