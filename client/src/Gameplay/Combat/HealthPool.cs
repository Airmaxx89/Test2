using System;

namespace Aethermoor.Gameplay.Combat;

/// <summary>
/// Engine-freier Lebenspunkte-Pool für Gegner und (später) Spieler. Kapselt Klemm- und
/// Todesregeln an einer Stelle, statt sie in Controllern zu duplizieren.
/// </summary>
/// <remarks>
/// Tote Ziele nehmen weder Schaden noch Heilung an (Wiederbelebung wird später ein
/// eigener, expliziter Vorgang). Clientseitig dient der Pool der lokalen Vertikale und
/// Vorhersage; verbindlich führt ihn später der Server (ADR-0002).
/// </remarks>
public sealed class HealthPool
{
    /// <param name="maxHealth">Maximales Leben (&gt; 0). Start: voll.</param>
    /// <exception cref="ArgumentOutOfRangeException">Wenn nicht positiv.</exception>
    public HealthPool(float maxHealth)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(maxHealth);
        Max = maxHealth;
        Current = maxHealth;
    }

    /// <summary>Maximales Leben.</summary>
    public float Max { get; }

    /// <summary>Aktuelles Leben (0..Max).</summary>
    public float Current { get; private set; }

    /// <summary>Aktueller Lebensanteil in [0, 1] (für Lebensbalken).</summary>
    public float Fraction => Current / Max;

    /// <summary>Ob das Ziel tot ist.</summary>
    public bool IsDead => Current <= 0f;

    /// <summary>
    /// Fügt Schaden zu. Liefert den tatsächlich abgezogenen Betrag (0 bei totem Ziel;
    /// beim Todesstoß nur bis 0 geklemmt).
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Bei negativem Betrag.</exception>
    public float ApplyDamage(float amount)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(amount);
        if (IsDead)
        {
            return 0f;
        }

        float applied = Math.Min(amount, Current);
        Current -= applied;
        return applied;
    }

    /// <summary>
    /// Heilt. Liefert den tatsächlich geheilten Betrag (0 bei totem Ziel; auf Max geklemmt).
    /// </summary>
    /// <exception cref="ArgumentOutOfRangeException">Bei negativem Betrag.</exception>
    public float Heal(float amount)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(amount);
        if (IsDead)
        {
            return 0f;
        }

        float applied = Math.Min(amount, Max - Current);
        Current += applied;
        return applied;
    }
}
