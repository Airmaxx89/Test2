namespace Aethermoor.Networking.Connection;

/// <summary>
/// Zustände der Verbindung zum Backend. Engine- und SDK-frei, damit die Zustandslogik
/// unabhängig von Nakama getestet werden kann (siehe ADR-0002, ARCHITECTURE §8).
/// </summary>
public enum ConnectionState
{
    /// <summary>Keine Verbindung; Ausgangszustand.</summary>
    Disconnected,

    /// <summary>Verbindungsaufbau läuft (erster Versuch).</summary>
    Connecting,

    /// <summary>Verbunden und authentifiziert.</summary>
    Connected,

    /// <summary>Verbindung verloren; automatischer Wiederaufbau läuft.</summary>
    Reconnecting,

    /// <summary>Verbindungsaufbau endgültig fehlgeschlagen (Nutzeraktion nötig).</summary>
    Failed,
}
