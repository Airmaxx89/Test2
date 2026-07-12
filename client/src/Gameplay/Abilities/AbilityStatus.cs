using System;

namespace Aethermoor.Gameplay.Abilities;

/// <summary>Anzeige-Zustand eines Fähigkeiten-Buttons.</summary>
public enum AbilityReadiness
{
    /// <summary>Wirken möglich.</summary>
    Ready = 0,

    /// <summary>Abklingzeit läuft (radiale Anzeige).</summary>
    OnCooldown = 1,

    /// <summary>Ressource reicht nicht (Button ausgegraut).</summary>
    Unaffordable = 2,
}

/// <summary>
/// Von der UI darstellbarer Zustand einer Fähigkeit.
/// </summary>
/// <param name="Readiness">Bereitschaftszustand.</param>
/// <param name="CooldownFraction">
/// Verbleibender Cooldown-Anteil in [0, 1] (1 = gerade gewirkt, 0 = bereit). Nur bei
/// <see cref="AbilityReadiness.OnCooldown"/> von 0 verschieden.
/// </param>
/// <param name="CooldownRemainingSeconds">Verbleibende Abklingzeit in Sekunden.</param>
public readonly record struct AbilityStatus(
    AbilityReadiness Readiness,
    float CooldownFraction,
    double CooldownRemainingSeconds);

/// <summary>
/// Leitet aus <see cref="AbilityCaster"/>-Zustand den Anzeige-Zustand eines Buttons ab.
/// Engine-frei und getestet, damit die Zustands-Prioritäten (Cooldown schlägt „zu teuer")
/// nicht in UI-Code verstreut werden.
/// </summary>
public static class AbilityStatusResolver
{
    /// <summary>Ermittelt den Anzeige-Zustand einer Fähigkeit zum Zeitpunkt <paramref name="now"/>.</summary>
    public static AbilityStatus Resolve(AbilityCaster caster, AbilityDefinition ability, double now)
    {
        ArgumentNullException.ThrowIfNull(caster);
        ArgumentNullException.ThrowIfNull(ability);

        double remaining = caster.GetCooldownRemaining(ability.Id, now);
        if (remaining > 0 && ability.CooldownSeconds > 0f)
        {
            float fraction = (float)Math.Clamp(remaining / ability.CooldownSeconds, 0.0, 1.0);
            return new AbilityStatus(AbilityReadiness.OnCooldown, fraction, remaining);
        }

        if (ability.ResourceCost > caster.CurrentResource)
        {
            return new AbilityStatus(AbilityReadiness.Unaffordable, 0f, 0.0);
        }

        return new AbilityStatus(AbilityReadiness.Ready, 0f, 0.0);
    }
}
