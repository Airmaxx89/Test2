using System;

namespace Aethermoor.Networking.Connection;

/// <summary>
/// Berechnet Wartezeiten für automatische Wiederverbindungsversuche mit exponentiellem
/// Backoff und Jitter. Der Jitter streut die Versuche vieler Clients zeitlich, um
/// Lastspitzen („Thundering Herd") auf dem Server nach einem Ausfall zu vermeiden.
/// </summary>
/// <remarks>
/// Engine- und SDK-frei; die Zufallsquelle ist injizierbar, damit das Backoff deterministisch
/// unit-getestet werden kann (siehe ARCHITECTURE §8).
/// </remarks>
public sealed class ReconnectBackoff
{
    private readonly TimeSpan _baseDelay;
    private readonly TimeSpan _maxDelay;
    private readonly double _multiplier;
    private readonly double _jitterRatio;
    private readonly int _maxAttempts;
    private readonly Func<double> _nextUnitRandom;

    /// <param name="baseDelay">Wartezeit vor dem ersten Wiederversuch (&gt; 0).</param>
    /// <param name="maxDelay">Obergrenze der Wartezeit (≥ <paramref name="baseDelay"/>).</param>
    /// <param name="multiplier">Wachstumsfaktor pro Versuch (≥ 1).</param>
    /// <param name="jitterRatio">Streuungsanteil in [0, 1] (0,2 = ±20 %).</param>
    /// <param name="maxAttempts">Maximale Versuche; <c>0</c> = unbegrenzt.</param>
    /// <param name="nextUnitRandom">Zufallsquelle in [0, 1); Standard: <see cref="Random.Shared"/>.</param>
    /// <exception cref="ArgumentOutOfRangeException">Bei ungültigen Parametern.</exception>
    public ReconnectBackoff(
        TimeSpan baseDelay,
        TimeSpan maxDelay,
        double multiplier = 2.0,
        double jitterRatio = 0.2,
        int maxAttempts = 0,
        Func<double>? nextUnitRandom = null)
    {
        if (baseDelay <= TimeSpan.Zero)
        {
            throw new ArgumentOutOfRangeException(nameof(baseDelay), baseDelay, "Muss > 0 sein.");
        }

        if (maxDelay < baseDelay)
        {
            throw new ArgumentOutOfRangeException(nameof(maxDelay), maxDelay, "Muss ≥ baseDelay sein.");
        }

        if (multiplier < 1.0)
        {
            throw new ArgumentOutOfRangeException(nameof(multiplier), multiplier, "Muss ≥ 1 sein.");
        }

        if (jitterRatio is < 0.0 or > 1.0)
        {
            throw new ArgumentOutOfRangeException(nameof(jitterRatio), jitterRatio, "Muss in [0, 1] liegen.");
        }

        if (maxAttempts < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(maxAttempts), maxAttempts, "Darf nicht negativ sein.");
        }

        _baseDelay = baseDelay;
        _maxDelay = maxDelay;
        _multiplier = multiplier;
        _jitterRatio = jitterRatio;
        _maxAttempts = maxAttempts;
        _nextUnitRandom = nextUnitRandom ?? Random.Shared.NextDouble;
    }

    /// <summary>Ob nach <paramref name="attempt"/> fehlgeschlagenen Versuchen weiter probiert wird.</summary>
    public bool ShouldRetry(int attempt) => _maxAttempts == 0 || attempt <= _maxAttempts;

    /// <summary>
    /// Liefert die Wartezeit vor dem <paramref name="attempt"/>-ten Versuch (1-basiert):
    /// exponentiell wachsend, auf <c>maxDelay</c> gedeckelt und mit Jitter versehen.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Wenn <paramref name="attempt"/> &lt; 1 ist.</exception>
    public TimeSpan NextDelay(int attempt)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(attempt, 1);

        double growth = _baseDelay.TotalSeconds * Math.Pow(_multiplier, attempt - 1);
        double capped = Math.Min(growth, _maxDelay.TotalSeconds);

        // Jitter: capped · (1 ± jitterRatio). nextUnitRandom() = 0.5 ergibt genau "capped".
        double jitterFactor = 1.0 + (_jitterRatio * ((2.0 * _nextUnitRandom()) - 1.0));
        double withJitter = capped * jitterFactor;

        double clamped = Math.Clamp(withJitter, 0.0, _maxDelay.TotalSeconds);
        return TimeSpan.FromSeconds(clamped);
    }
}
