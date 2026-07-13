using System;
using System.Collections.Generic;

namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Engine-freier Wirk-Zustand eines Charakters: bekannte Fähigkeiten, Ressourcenpool und
/// Abklingzeiten. Prüft Wirkversuche (bekannt? bereit? bezahlbar? in Reichweite?) und bucht
/// bei Erfolg Kosten und Abklingzeit.
/// </summary>
/// <remarks>
/// <para>
/// Die Zeit wird als Parameter injiziert (Sekunden, monoton) — dadurch ist die gesamte
/// Cooldown-Logik deterministisch in CI testbar (ARCHITECTURE §8) und Client wie Server
/// könnten dieselbe Klasse verwenden.
/// </para>
/// <para>
/// <b>Autorität:</b> Clientseitig dient diese Prüfung der Vorhersage und dem UI-Feedback;
/// die verbindliche Validierung derselben Regeln erfolgt serverseitig (ADR-0002). Ein
/// manipulierter Client kann sich hier nur selbst belügen.
/// </para>
/// </remarks>
public sealed class AbilityCaster
{
    private readonly Dictionary<string, AbilityDefinition> _abilities = new();
    private readonly Dictionary<string, double> _cooldownReadyAt = new();

    /// <param name="abilities">Bekannte Fähigkeiten (eindeutige IDs, valide Werte).</param>
    /// <param name="maxResource">Maximaler Ressourcenpool (&gt; 0). Start: voll.</param>
    /// <exception cref="ArgumentNullException">Wenn <paramref name="abilities"/> null ist.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Wenn <paramref name="maxResource"/> nicht positiv ist.</exception>
    /// <exception cref="ArgumentException">
    /// Bei doppelten IDs oder ungültigen Definitionswerten — Datenfehler sollen beim Laden
    /// auffallen, nicht erst im Kampf.
    /// </exception>
    public AbilityCaster(IEnumerable<AbilityDefinition> abilities, float maxResource)
    {
        ArgumentNullException.ThrowIfNull(abilities);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(maxResource);

        foreach (AbilityDefinition ability in abilities)
        {
            ValidateDefinition(ability);
            if (!_abilities.TryAdd(ability.Id, ability))
            {
                throw new ArgumentException(
                    $"Doppelte Fähigkeits-ID '{ability.Id}'.", nameof(abilities));
            }
        }

        MaxResource = maxResource;
        CurrentResource = maxResource;
    }

    /// <summary>Maximaler Ressourcenpool.</summary>
    public float MaxResource { get; }

    /// <summary>Aktuell verfügbare Ressource.</summary>
    public float CurrentResource { get; private set; }

    /// <summary>Alle bekannten Fähigkeiten (für UI-Aufbau der Zauberleiste).</summary>
    public IReadOnlyCollection<AbilityDefinition> Abilities => _abilities.Values;

    /// <summary>
    /// Versucht, eine Fähigkeit zu wirken. Bei Erfolg werden Kosten abgezogen und die
    /// Abklingzeit gestartet.
    /// </summary>
    /// <param name="abilityId">ID der Fähigkeit.</param>
    /// <param name="now">Aktuelle Zeit in Sekunden (monoton).</param>
    /// <param name="distanceToTarget">
    /// Distanz zum Ziel in Weltpixeln. Wird nur geprüft, wenn die Fähigkeit eine
    /// Reichweite &gt; 0 besitzt.
    /// </param>
    /// <param name="reason">Ablehnungsgrund, oder <see cref="CastFailureReason.None"/> bei Erfolg.</param>
    public bool TryCast(string abilityId, double now, float distanceToTarget, out CastFailureReason reason)
    {
        if (!_abilities.TryGetValue(abilityId, out AbilityDefinition? ability))
        {
            reason = CastFailureReason.UnknownAbility;
            return false;
        }

        if (GetCooldownRemaining(abilityId, now) > 0)
        {
            reason = CastFailureReason.OnCooldown;
            return false;
        }

        if (ability.ResourceCost > CurrentResource)
        {
            reason = CastFailureReason.InsufficientResource;
            return false;
        }

        if (ability.Range > 0f && distanceToTarget > ability.Range)
        {
            reason = CastFailureReason.OutOfRange;
            return false;
        }

        CurrentResource -= ability.ResourceCost;
        _cooldownReadyAt[abilityId] = now + ability.CooldownSeconds;
        reason = CastFailureReason.None;
        return true;
    }

    /// <summary>
    /// Verbleibende Abklingzeit in Sekunden (0, wenn bereit oder unbekannt) — Basis der
    /// Cooldown-Anzeige auf den Buttons.
    /// </summary>
    public double GetCooldownRemaining(string abilityId, double now)
    {
        if (!_cooldownReadyAt.TryGetValue(abilityId, out double readyAt))
        {
            return 0;
        }

        double remaining = readyAt - now;
        return remaining > 0 ? remaining : 0;
    }

    /// <summary>Füllt Ressource auf (Regeneration, Tränke); geklemmt auf den Maximalwert.</summary>
    /// <exception cref="ArgumentOutOfRangeException">Bei negativem Betrag.</exception>
    public void RestoreResource(float amount)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(amount);
        CurrentResource = Math.Min(CurrentResource + amount, MaxResource);
    }

    private static void ValidateDefinition(AbilityDefinition ability)
    {
        if (string.IsNullOrWhiteSpace(ability.Id))
        {
            throw new ArgumentException("Fähigkeit ohne ID.", nameof(ability));
        }

        if (ability.CooldownSeconds < 0f || ability.ResourceCost < 0f || ability.Magnitude < 0f)
        {
            throw new ArgumentException(
                $"Fähigkeit '{ability.Id}' hat negative Werte (Cooldown/Kosten/Wirkstärke).",
                nameof(ability));
        }

        if (ability.AppliesMarker.Length > 0 && ability.MarkerDurationSeconds <= 0f)
        {
            throw new ArgumentException(
                $"Fähigkeit '{ability.Id}' setzt einen Marker ohne gültige Dauer.",
                nameof(ability));
        }

        if (ability.ComboBonusMultiplier <= 0f)
        {
            throw new ArgumentException(
                $"Fähigkeit '{ability.Id}' hat einen nicht-positiven Combo-Multiplikator.",
                nameof(ability));
        }
    }
}
