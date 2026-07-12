using System;

namespace Aethermoor.Networking.Model;

/// <summary>
/// Engine-freie Beschreibung des Backend-Endpunkts. Wird aus der <c>GameConfig</c> abgeleitet
/// und vom Netzwerkdienst zum Verbindungsaufbau genutzt.
/// </summary>
public readonly record struct ServerEndpoint(string Scheme, string Host, int Port, string ServerKey)
{
    /// <summary>Basis-URI des Servers, z. B. <c>http://127.0.0.1:7350</c>.</summary>
    public string BaseUri => $"{Scheme}://{Host}:{Port}";
}

/// <summary>
/// Anmeldedaten für die Authentifizierung. Startet mit gerätebasierter Authentifizierung
/// (ein Gerät = ein Standard-Login); weitere Verfahren (E-Mail, Social) sind spätere Erweiterungen.
/// </summary>
/// <param name="DeviceId">Stabile, gerätespezifische Kennung.</param>
/// <param name="Username">Optionaler Anzeigename bei Erstanmeldung.</param>
public readonly record struct AuthCredentials(string DeviceId, string? Username = null);

/// <summary>
/// Engine-/SDK-freie Repräsentation einer authentifizierten Sitzung. Kapselt die Nakama-Session,
/// ohne deren Typen nach außen zu tragen (ADR-0002).
/// </summary>
/// <param name="UserId">Serverseitige Nutzer-ID.</param>
/// <param name="Username">Anzeigename.</param>
/// <param name="AuthToken">Sitzungstoken (vertraulich — nicht protokollieren, nicht broadcasten).</param>
/// <param name="ExpiresAt">Ablaufzeitpunkt des Tokens.</param>
public sealed record SessionInfo(string UserId, string Username, string AuthToken, DateTimeOffset ExpiresAt)
{
    /// <summary>Ob die Sitzung zum angegebenen Zeitpunkt abgelaufen ist.</summary>
    public bool IsExpired(DateTimeOffset now) => now >= ExpiresAt;
}
