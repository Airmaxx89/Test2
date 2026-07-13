using System;

namespace Aethermoor.Gameplay.Progression;

/// <summary>
/// Engine-freie XP-/Level-Verwaltung eines Charakters (Level 1 bis Cap, GAME_DESIGN §6).
/// Die Kurve ist parametrisch (<c>benötigt(level) = basis · level^exponent</c>), Überschuss
/// wird über Level-Grenzen getragen, am Cap verfällt weitere XP.
/// </summary>
/// <remarks>
/// Deterministisch und in CI getestet (ARCHITECTURE §8). Verbindlich wird XP später
/// serverseitig vergeben und persistiert (ADR-0002); dieselbe Klasse ist dafür vorbereitet.
/// </remarks>
public sealed class ExperienceTracker
{
    private readonly float _baseXpPerLevel;
    private readonly float _exponent;
    private readonly int _maxLevel;

    /// <param name="baseXpPerLevel">Basis-XP der Kurve (&gt; 0).</param>
    /// <param name="exponent">Kurven-Exponent (≥ 1; 1 = linear).</param>
    /// <param name="maxLevel">Level-Cap (≥ 2). Start-Cap laut Design-Bibel: 55.</param>
    /// <exception cref="ArgumentOutOfRangeException">Bei ungültigen Parametern.</exception>
    public ExperienceTracker(float baseXpPerLevel = 100f, float exponent = 1.5f, int maxLevel = 55)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(baseXpPerLevel);
        ArgumentOutOfRangeException.ThrowIfLessThan(exponent, 1f);
        ArgumentOutOfRangeException.ThrowIfLessThan(maxLevel, 2);

        _baseXpPerLevel = baseXpPerLevel;
        _exponent = exponent;
        _maxLevel = maxLevel;
    }

    /// <summary>Aktuelles Level (startet bei 1).</summary>
    public int Level { get; private set; } = 1;

    /// <summary>Gesammelte XP innerhalb des aktuellen Levels.</summary>
    public float CurrentXp { get; private set; }

    /// <summary>Ob das Level-Cap erreicht ist.</summary>
    public bool IsMaxLevel => Level >= _maxLevel;

    /// <summary>Benötigte XP bis zum nächsten Level (0 am Cap).</summary>
    public float XpToNextLevel => IsMaxLevel ? 0f : XpRequiredForLevel(Level);

    /// <summary>Fortschrittsanteil im aktuellen Level in [0, 1] (1 am Cap).</summary>
    public float ProgressFraction => IsMaxLevel ? 1f : CurrentXp / XpToNextLevel;

    /// <summary>Benötigte XP für den Aufstieg VON <paramref name="level"/> auf das nächste.</summary>
    public float XpRequiredForLevel(int level)
        => MathF.Round(_baseXpPerLevel * MathF.Pow(level, _exponent));

    /// <summary>
    /// Vergibt XP und liefert die Anzahl dabei erreichter Level-Aufstiege. Überschuss trägt
    /// über Grenzen; am Cap verfällt weitere XP.
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Bei negativem Betrag.</exception>
    public int GrantXp(float amount)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(amount);
        if (IsMaxLevel)
        {
            return 0;
        }

        CurrentXp += amount;

        int levelUps = 0;
        while (!IsMaxLevel && CurrentXp >= XpRequiredForLevel(Level))
        {
            CurrentXp -= XpRequiredForLevel(Level);
            Level++;
            levelUps++;
        }

        if (IsMaxLevel)
        {
            CurrentXp = 0f; // am Cap verfällt Überschuss
        }

        return levelUps;
    }
}
