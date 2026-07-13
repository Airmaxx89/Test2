using System;
using System.Collections.Generic;

namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Engine-freie Verwaltung von Combo-Markern auf Zielen (GAME_DESIGN §7): Fähigkeiten
/// setzen benannte Marker mit Ablaufzeit (z. B. „wappenbruch"), Finisher verbrauchen sie
/// für Bonuswirkung. Belohnt Reihenfolge statt Button-Spam.
/// </summary>
/// <remarks>
/// Zeit wird injiziert (deterministisch testbar, ARCHITECTURE §8); abgelaufene Marker
/// werden bei Zugriff bereinigt. Verbindlich wird die Combo-Auflösung später serverseitig
/// geführt (ADR-0002) — dieselbe Klasse ist dafür vorbereitet.
/// </remarks>
public sealed class ComboTracker
{
    private readonly Dictionary<(long TargetId, string Marker), double> _expiresAt = new();

    /// <summary>
    /// Setzt (oder erneuert) einen Marker auf einem Ziel.
    /// </summary>
    /// <param name="targetId">Stabile Ziel-Kennung.</param>
    /// <param name="marker">Marker-Name (nicht leer).</param>
    /// <param name="now">Aktuelle Zeit in Sekunden (monoton).</param>
    /// <param name="durationSeconds">Gültigkeitsdauer (&gt; 0).</param>
    /// <exception cref="ArgumentException">Bei leerem Marker.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Bei nicht-positiver Dauer.</exception>
    public void ApplyMarker(long targetId, string marker, double now, double durationSeconds)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(marker);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(durationSeconds);

        _expiresAt[(targetId, marker)] = now + durationSeconds;
    }

    /// <summary>Ob der Marker auf dem Ziel aktiv (gesetzt und nicht abgelaufen) ist.</summary>
    public bool HasMarker(long targetId, string marker, double now)
    {
        if (!_expiresAt.TryGetValue((targetId, marker), out double expiresAt))
        {
            return false;
        }

        if (now >= expiresAt)
        {
            _expiresAt.Remove((targetId, marker)); // lazy Bereinigung
            return false;
        }

        return true;
    }

    /// <summary>
    /// Verbraucht den Marker, falls aktiv. Liefert <c>true</c> genau dann, wenn er vorhanden
    /// und gültig war — er ist danach entfernt (ein Finisher pro Marker).
    /// </summary>
    public bool TryConsumeMarker(long targetId, string marker, double now)
    {
        if (!HasMarker(targetId, marker, now))
        {
            return false;
        }

        _expiresAt.Remove((targetId, marker));
        return true;
    }

    /// <summary>Entfernt alle Marker eines Ziels (Tod, Despawn, Reset).</summary>
    public void ClearTarget(long targetId)
    {
        var stale = new List<(long, string)>();
        foreach ((long TargetId, string Marker) key in _expiresAt.Keys)
        {
            if (key.TargetId == targetId)
            {
                stale.Add(key);
            }
        }

        foreach ((long, string) key in stale)
        {
            _expiresAt.Remove(key);
        }
    }
}
