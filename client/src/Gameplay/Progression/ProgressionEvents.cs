using Aethermoor.Core.Events;

namespace Aethermoor.Gameplay.Progression;

/// <summary>
/// XP wurde vergeben (auch mit Betrag 0 als Initialmeldung fürs HUD). Enthält den
/// vollständigen Anzeigezustand, damit die XP-Leiste zustandslos bleiben kann.
/// </summary>
public readonly record struct ExperienceGainedEvent(
    float Amount,
    int Level,
    float CurrentXp,
    float XpToNextLevel,
    float ProgressFraction) : IGameEvent;

/// <summary>Level-Aufstieg (Fanfare, VFX, Attributs-Neuberechnung docken hier an).</summary>
public readonly record struct LevelUpEvent(int NewLevel) : IGameEvent;
