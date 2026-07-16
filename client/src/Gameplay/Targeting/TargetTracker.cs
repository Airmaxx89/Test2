using System;
using System.Collections.Generic;
using System.Numerics;

namespace Aethermoor.Gameplay.Targeting;

/// <summary>
/// Engine-freie Zielverfolgung: hält über den <see cref="SmartTargetSelector"/> das aktuell
/// anvisierte Ziel und meldet, wenn es sich ändert (für Ziel-Markierung/UI). Kapselt die
/// Auswahl- und Identitätslogik, damit sie testbar ist und von lokalem wie
/// serverautoritativem Kampf geteilt werden kann.
/// </summary>
public sealed class TargetTracker
{
    private readonly SmartTargetSelector _selector;

    /// <param name="selector">Die Auswahlstrategie (Reichweite/Blickkegel/Gewichtung).</param>
    /// <exception cref="ArgumentNullException">Wenn <paramref name="selector"/> null ist.</exception>
    public TargetTracker(SmartTargetSelector selector)
    {
        ArgumentNullException.ThrowIfNull(selector);
        _selector = selector;
    }

    /// <summary>ID des aktuellen Ziels, oder <c>null</c> wenn keines gewählt ist.</summary>
    public long? CurrentTargetId { get; private set; }

    /// <summary>
    /// Wählt aus den Kandidaten das beste Ziel und aktualisiert <see cref="CurrentTargetId"/>.
    /// </summary>
    /// <returns><c>true</c>, wenn sich das Ziel gegenüber dem Vorframe geändert hat.</returns>
    public bool Update(Vector2 origin, Vector2 facing, IReadOnlyList<TargetCandidate> candidates)
    {
        long? selected = _selector.SelectTarget(origin, facing, candidates);
        if (selected == CurrentTargetId)
        {
            return false;
        }

        CurrentTargetId = selected;
        return true;
    }

    /// <summary>Hebt die Zielwahl auf; meldet Änderung, falls zuvor ein Ziel gewählt war.</summary>
    public bool Clear()
    {
        if (CurrentTargetId is null)
        {
            return false;
        }

        CurrentTargetId = null;
        return true;
    }
}
