using System;
using System.Numerics;

namespace Aethermoor.World.Camera;

/// <summary>
/// Engine-freie, bildratenunabhängige Glättung einer Kameraposition hin zu einem Ziel.
/// Liefert weiches „Nachziehen" der Kamera, ohne bei schwankender Bildrate zu ruckeln —
/// wichtig für Mobilgeräte mit variabler FPS (siehe GAME_DESIGN §15).
/// </summary>
/// <remarks>
/// Verwendet exponentielle Glättung: der pro Frame zurückgelegte Anteil ist
/// <c>1 - e^(-smoothing · dt)</c>. Das ist unabhängig von der Framerate (gleiche gefühlte
/// Trägheit bei 30 wie bei 60 FPS) — im Gegensatz zu einem naiven <c>Lerp(a, b, konstante)</c>.
/// Bewusst Godot-frei gehalten und damit in CI testbar (ARCHITECTURE §8).
/// </remarks>
public sealed class CameraFollowSolver
{
    private readonly float _smoothing;

    /// <param name="smoothing">
    /// Glättungsrate (≥ 0). Höher = schnelleres Nachziehen. <c>0</c> bedeutet sofortiges Folgen.
    /// </param>
    /// <exception cref="ArgumentOutOfRangeException">Wenn <paramref name="smoothing"/> negativ ist.</exception>
    public CameraFollowSolver(float smoothing)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(smoothing);
        _smoothing = smoothing;
    }

    /// <summary>
    /// Berechnet die neue Kameraposition für einen Frame.
    /// </summary>
    /// <param name="current">Aktuelle Kameraposition.</param>
    /// <param name="target">Zielposition (z. B. die des Spielers).</param>
    /// <param name="deltaSeconds">Vergangene Zeit seit dem letzten Frame in Sekunden.</param>
    public Vector2 Step(Vector2 current, Vector2 target, float deltaSeconds)
    {
        // Ohne Zeitfortschritt keine Änderung; ohne Glättung sofort am Ziel.
        if (deltaSeconds <= 0f)
        {
            return current;
        }

        if (_smoothing <= 0f)
        {
            return target;
        }

        float t = 1f - MathF.Exp(-_smoothing * deltaSeconds);
        return Vector2.Lerp(current, target, t);
    }
}
