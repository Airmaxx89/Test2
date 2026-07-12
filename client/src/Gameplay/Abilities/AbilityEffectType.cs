namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Grundlegende Wirkungsart einer Fähigkeit. Startumfang für Milestone 4 (Wächter-Vertikale);
/// weitere Arten (Buff, Debuff, Kontrolle, Beschwörung) werden als neue Werte ergänzt —
/// bestehende Daten bleiben gültig (Open/Closed).
/// </summary>
public enum AbilityEffectType
{
    /// <summary>Fügt dem Ziel Schaden zu.</summary>
    Damage = 0,

    /// <summary>Heilt das Ziel.</summary>
    Heal = 1,
}
