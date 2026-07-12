using Aethermoor.Core.Events;
using Aethermoor.Networking.Connection;

namespace Aethermoor.Networking;

/// <summary>Verbindungszustand hat sich geändert (für HUD-Indikatoren, Reconnect-Overlays).</summary>
public readonly record struct NetworkStateChangedEvent(
    ConnectionState Previous, ConnectionState Current) : IGameEvent;

/// <summary>
/// Erfolgreiche Authentifizierung. Trägt bewusst nur nicht-sensible Kennungen — das
/// Sitzungstoken wird niemals über den EventBus verteilt.
/// </summary>
public readonly record struct NetworkAuthenticatedEvent(string UserId, string Username) : IGameEvent;

/// <summary>Netzwerkfehler mit menschenlesbarer Ursache (für Protokoll und Wiederholen-UI).</summary>
public readonly record struct NetworkErrorEvent(string Reason) : IGameEvent;
