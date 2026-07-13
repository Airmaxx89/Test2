using System;

namespace Aethermoor.Gameplay.Combat;

/// <summary>
/// Engine-freier Taktgeber für wiederkehrende Angriffe: erlaubt den ersten Angriff sofort
/// und danach höchstens einen pro Intervall. Zeit wird injiziert — deterministisch testbar
/// (ARCHITECTURE §8) und identisch auf Client und (später) Server nutzbar.
/// </summary>
public sealed class AttackTicker
{
    private readonly double _intervalSeconds;
    private double _nextReadyAt;

    /// <param name="intervalSeconds">Mindestabstand zwischen zwei Angriffen (&gt; 0).</param>
    /// <exception cref="ArgumentOutOfRangeException">Wenn das Intervall nicht positiv ist.</exception>
    public AttackTicker(double intervalSeconds)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(intervalSeconds);
        _intervalSeconds = intervalSeconds;
    }

    /// <summary>
    /// Versucht anzugreifen. Liefert <c>true</c> höchstens einmal pro Intervall und bucht
    /// dabei den nächsten frühesten Angriffszeitpunkt.
    /// </summary>
    /// <param name="now">Aktuelle Zeit in Sekunden (monoton).</param>
    public bool TryAttack(double now)
    {
        if (now < _nextReadyAt)
        {
            return false;
        }

        _nextReadyAt = now + _intervalSeconds;
        return true;
    }

    /// <summary>Setzt den Taktgeber zurück (nächster Angriff sofort möglich).</summary>
    public void Reset() => _nextReadyAt = 0;
}
