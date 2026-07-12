using System.Threading;
using System.Threading.Tasks;
using Aethermoor.Core.Services;
using Aethermoor.Networking.Connection;
using Aethermoor.Networking.Model;

namespace Aethermoor.Networking;

/// <summary>
/// Stabiler, SDK-freier Vertrag für die Backend-Anbindung. Der gesamte Client spricht
/// ausschließlich mit diesem Interface; Nakama-Typen bleiben in der Implementierung gekapselt
/// (ADR-0002). So bliebe ein Backend-Wechsel lokal.
/// </summary>
public interface INetworkService : IService
{
    /// <summary>Aktueller Verbindungszustand.</summary>
    ConnectionState State { get; }

    /// <summary>Aktive Sitzung, oder <c>null</c>, wenn nicht verbunden/authentifiziert.</summary>
    SessionInfo? Session { get; }

    /// <summary>
    /// Baut die Verbindung auf und authentifiziert. Wiederholte Aufrufe bei bereits
    /// bestehender/laufender Verbindung sind wirkungslos.
    /// </summary>
    Task ConnectAsync(AuthCredentials credentials, CancellationToken cancellationToken = default);

    /// <summary>Trennt die Verbindung und verwirft die Sitzung.</summary>
    Task DisconnectAsync();
}
