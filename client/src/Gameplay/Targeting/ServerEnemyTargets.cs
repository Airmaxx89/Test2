using System.Collections.Generic;
using System.Numerics;
using Aethermoor.Networking.Replication;

namespace Aethermoor.Gameplay.Targeting;

/// <summary>
/// Brücke von den serverautoritativen Gegnern (<see cref="ServerEnemyReplicator"/>) zu
/// <see cref="TargetCandidate"/>s für die Zielwahl. Die Spawn-ID ist zugleich die Ziel-ID
/// (und das <c>target</c>-Feld im Cast an den Server) — im Online-Kampf arbeitet der
/// getestete <see cref="SmartTargetSelector"/>/<see cref="TargetTracker"/> damit unverändert.
/// </summary>
/// <remarks>
/// Bewusst in der Gameplay-Schicht (Gameplay darf von Networking abhängen, nicht umgekehrt —
/// ARCHITECTURE §2.1), engine-frei und in CI testbar.
/// </remarks>
public static class ServerEnemyTargets
{
    /// <summary>
    /// Füllt <paramref name="into"/> mit den interpolierten Positionen der Server-Gegner;
    /// tote Gegner werden als nicht anvisierbar markiert (der Selektor überspringt sie).
    /// </summary>
    public static void Collect(ServerEnemyReplicator enemies, double now, List<TargetCandidate> into)
    {
        System.ArgumentNullException.ThrowIfNull(enemies);
        System.ArgumentNullException.ThrowIfNull(into);

        foreach (int sid in enemies.Sids)
        {
            Vector2? position = enemies.SamplePosition(sid, now);
            if (position is null)
            {
                continue;
            }

            into.Add(new TargetCandidate(sid, position.Value, enemies.IsAlive(sid)));
        }
    }
}
