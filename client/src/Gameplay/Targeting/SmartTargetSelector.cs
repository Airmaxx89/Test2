using System;
using System.Collections.Generic;
using System.Numerics;

namespace Aethermoor.Gameplay.Targeting;

/// <summary>
/// Engine-freie „Smart Targeting"-Auswahl: wählt aus einer Menge von Kandidaten das für den
/// Spieler naheliegendste Ziel — innerhalb von Reichweite und Blickkegel, gewichtet nach Nähe
/// und Ausrichtung. Entlastet die Touch-Bedienung, weil der Spieler nicht exakt tippen muss
/// (GAME_DESIGN §7, §13).
/// </summary>
/// <remarks>
/// <para>
/// Bewusst Godot-frei (nur <c>System.Numerics</c>) und vollständig in CI testbar
/// (siehe ARCHITECTURE §8). Der spätere Gegner-/KI-Milestone liefert die konkreten
/// <see cref="TargetCandidate"/>-Momentaufnahmen aus den Szenenknoten.
/// </para>
/// <para>
/// Fehlt eine Blickrichtung (Nullvektor), wird der Kegelfilter deaktiviert und rein nach Nähe
/// ausgewählt (360°). Bei Punktgleichheit gewinnt der zuerst geprüfte Kandidat (stabil).
/// </para>
/// </remarks>
public sealed class SmartTargetSelector
{
    private readonly float _maxRange;
    private readonly float _coneCosThreshold;
    private readonly float _distanceWeight;

    /// <param name="maxRange">Maximale Zielreichweite (&gt; 0).</param>
    /// <param name="coneHalfAngleDegrees">
    /// Halber Öffnungswinkel des Blickkegels in Grad, im Bereich (0, 180].
    /// </param>
    /// <param name="distanceWeight">
    /// Gewichtung zwischen Nähe (1) und Ausrichtung (0), im Bereich [0, 1]. Standard 0,5.
    /// </param>
    /// <exception cref="ArgumentOutOfRangeException">Bei ungültigen Parametern.</exception>
    public SmartTargetSelector(float maxRange, float coneHalfAngleDegrees, float distanceWeight = 0.5f)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(maxRange);
        if (coneHalfAngleDegrees is <= 0f or > 180f)
        {
            throw new ArgumentOutOfRangeException(
                nameof(coneHalfAngleDegrees), coneHalfAngleDegrees, "Winkel muss in (0, 180] liegen.");
        }

        if (distanceWeight is < 0f or > 1f)
        {
            throw new ArgumentOutOfRangeException(
                nameof(distanceWeight), distanceWeight, "Gewichtung muss in [0, 1] liegen.");
        }

        _maxRange = maxRange;
        _coneCosThreshold = MathF.Cos(coneHalfAngleDegrees * (MathF.PI / 180f));
        _distanceWeight = distanceWeight;
    }

    /// <summary>
    /// Wählt das beste Ziel aus den Kandidaten oder <c>null</c>, wenn keines geeignet ist.
    /// </summary>
    /// <param name="origin">Position des Spielers.</param>
    /// <param name="facing">Blickrichtung (darf Nullvektor sein → 360°-Auswahl).</param>
    /// <param name="candidates">Zu prüfende Kandidaten.</param>
    public long? SelectTarget(Vector2 origin, Vector2 facing, IReadOnlyList<TargetCandidate> candidates)
    {
        ArgumentNullException.ThrowIfNull(candidates);

        bool hasFacing = facing.Length() > float.Epsilon;
        Vector2 face = hasFacing ? Vector2.Normalize(facing) : Vector2.Zero;

        long? best = null;
        float bestScore = float.NegativeInfinity;

        foreach (TargetCandidate candidate in candidates)
        {
            if (!candidate.IsTargetable)
            {
                continue;
            }

            Vector2 toTarget = candidate.Position - origin;
            float distance = toTarget.Length();
            if (distance > _maxRange)
            {
                continue;
            }

            // Ausrichtung: 1 = direkt voraus. Bei fehlender Blickrichtung oder Deckungsgleichheit neutral.
            float alignment = 1f;
            if (hasFacing && distance > float.Epsilon)
            {
                alignment = Vector2.Dot(toTarget / distance, face);
                if (alignment < _coneCosThreshold)
                {
                    continue; // außerhalb des Blickkegels
                }
            }

            float distanceScore = 1f - (distance / _maxRange); // 1 nah … 0 am Rand
            float alignmentScore = (alignment + 1f) * 0.5f;     // 0 … 1
            float score = (_distanceWeight * distanceScore) + ((1f - _distanceWeight) * alignmentScore);

            if (score > bestScore)
            {
                bestScore = score;
                best = candidate.Id;
            }
        }

        return best;
    }
}
