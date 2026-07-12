using System.Threading;
using System.Threading.Tasks;
using Aethermoor.Core.Services;
using Aethermoor.Networking.Protocol;

namespace Aethermoor.Networking;

/// <summary>
/// SDK-freier Vertrag für die Teilnahme am autoritativen Bewegungs-Match. Ergänzt
/// <see cref="INetworkService"/> um Match-Beitritt, Eingabeversand und Snapshot-Empfang;
/// implementiert vom Nakama-Adapter (ADR-0002 — keine SDK-Typen in dieser Schnittstelle).
/// </summary>
/// <remarks>
/// <para>
/// <b>Threading:</b> Snapshots treffen auf dem Netzwerk-Thread ein. Sie werden deshalb
/// intern gepuffert und über <see cref="TryDequeueSnapshot"/> abgeholt — der Godot-Consumer
/// entleert die Warteschlange in seinem Frame-Update und bleibt damit auf dem Main-Thread
/// (kein unsynchronisierter Szenenzugriff). Bewusst kein EventBus für diesen Pfad: dessen
/// Handler liefen sonst auf dem Netzwerk-Thread.
/// </para>
/// </remarks>
public interface IMatchClient : IService
{
    /// <summary>Ob aktuell ein Match aktiv ist.</summary>
    bool IsInMatch { get; }

    /// <summary>
    /// Tritt dem Bewegungs-Match bei (über den Server-RPC <c>find_or_create_movement_match</c>).
    /// Erfordert eine bestehende Verbindung.
    /// </summary>
    Task JoinMovementMatchAsync(CancellationToken cancellationToken = default);

    /// <summary>Verlässt das aktuelle Match (idempotent).</summary>
    Task LeaveMatchAsync();

    /// <summary>
    /// Sendet eine Bewegungs-Eingabe an den Server (fire-and-forget; Sendefehler werden
    /// protokolliert, nicht geworfen — der nächste Frame sendet ohnehin erneut).
    /// </summary>
    void SendMovementInput(MovementInputPayload input);

    /// <summary>Holt den nächsten gepufferten Server-Snapshot ab, sofern vorhanden.</summary>
    bool TryDequeueSnapshot(out MovementSnapshot? snapshot);
}
