using System;
using System.Collections.Generic;

namespace Aethermoor.Gameplay.Zones;

/// <summary>
/// Engine-freie Respawn-Verwaltung einer Zone: Spawnpunkte melden besiegte Gegner an,
/// der Scheduler liefert fällige Wiederbelebungen zurück. Zeit wird injiziert —
/// deterministisch testbar und später serverseitig identisch nutzbar (ADR-0002).
/// </summary>
public sealed class RespawnScheduler
{
    private readonly Dictionary<int, double> _respawnAt = new();

    /// <summary>Plant den Respawn eines Spawnpunkts; erneutes Planen überschreibt.</summary>
    /// <param name="spawnId">Kennung des Spawnpunkts.</param>
    /// <param name="now">Aktuelle Zeit in Sekunden (monoton).</param>
    /// <param name="delaySeconds">Wartezeit bis zum Respawn (&gt; 0).</param>
    /// <exception cref="ArgumentOutOfRangeException">Bei nicht-positiver Wartezeit.</exception>
    public void Schedule(int spawnId, double now, double delaySeconds)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(delaySeconds);
        _respawnAt[spawnId] = now + delaySeconds;
    }

    /// <summary>Ob für den Spawnpunkt ein Respawn aussteht.</summary>
    public bool IsPending(int spawnId) => _respawnAt.ContainsKey(spawnId);

    /// <summary>
    /// Sammelt alle fälligen Spawnpunkte in <paramref name="due"/> (angehängt) und entfernt
    /// sie aus der Planung. Die Liste wird vom Aufrufer gestellt — kein per-Frame-Müll
    /// (CODING_STANDARDS §7).
    /// </summary>
    public void CollectDue(double now, List<int> due)
    {
        ArgumentNullException.ThrowIfNull(due);

        int firstNewIndex = due.Count; // nur in diesem Aufruf gesammelte Einträge entfernen
        foreach (KeyValuePair<int, double> entry in _respawnAt)
        {
            if (now >= entry.Value)
            {
                due.Add(entry.Key);
            }
        }

        for (int i = firstNewIndex; i < due.Count; i++)
        {
            _respawnAt.Remove(due[i]);
        }
    }
}
