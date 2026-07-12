using System;
using Aethermoor.Gameplay.Abilities;
using Xunit;

namespace Aethermoor.Tests;

public sealed class AbilityStatusResolverTests
{
    private static AbilityDefinition Ability(float cooldown = 10f, float cost = 20f)
        => new("test.faehigkeit", "Fähigkeit", cooldown, cost, 0f, AbilityEffectType.Damage, 10f);

    [Fact]
    public void FreshCaster_IsReady()
    {
        AbilityDefinition ability = Ability();
        var caster = new AbilityCaster(new[] { ability }, 100f);

        AbilityStatus status = AbilityStatusResolver.Resolve(caster, ability, 0.0);

        Assert.Equal(AbilityReadiness.Ready, status.Readiness);
        Assert.Equal(0f, status.CooldownFraction);
        Assert.Equal(0.0, status.CooldownRemainingSeconds);
    }

    [Fact]
    public void AfterCast_ReportsCooldownWithFraction()
    {
        AbilityDefinition ability = Ability(cooldown: 10f, cost: 20f);
        var caster = new AbilityCaster(new[] { ability }, 100f);
        caster.TryCast(ability.Id, 100.0, 0f, out _);

        // 4 Sekunden später: 6 von 10 Sekunden verbleiben -> Fraktion 0,6.
        AbilityStatus status = AbilityStatusResolver.Resolve(caster, ability, 104.0);

        Assert.Equal(AbilityReadiness.OnCooldown, status.Readiness);
        Assert.Equal(0.6f, status.CooldownFraction, precision: 4);
        Assert.Equal(6.0, status.CooldownRemainingSeconds, precision: 4);
    }

    [Fact]
    public void CooldownElapsed_ReturnsToReady()
    {
        AbilityDefinition ability = Ability(cooldown: 10f, cost: 20f);
        var caster = new AbilityCaster(new[] { ability }, 100f);
        caster.TryCast(ability.Id, 0.0, 0f, out _);
        caster.RestoreResource(100f);

        AbilityStatus status = AbilityStatusResolver.Resolve(caster, ability, 10.0);

        Assert.Equal(AbilityReadiness.Ready, status.Readiness);
    }

    [Fact]
    public void InsufficientResource_ReportsUnaffordable()
    {
        AbilityDefinition ability = Ability(cooldown: 0f, cost: 80f);
        var caster = new AbilityCaster(new[] { ability }, 100f);
        caster.TryCast(ability.Id, 0.0, 0f, out _); // 100 -> 20 (kein Cooldown)

        AbilityStatus status = AbilityStatusResolver.Resolve(caster, ability, 1.0);

        Assert.Equal(AbilityReadiness.Unaffordable, status.Readiness);
    }

    [Fact]
    public void Cooldown_TakesPriorityOverUnaffordable()
    {
        // Nach dem Wirken sind sowohl Cooldown aktiv als auch Ressource zu knapp:
        // Die Anzeige zeigt den Cooldown (nützlichere Information für den Spieler).
        AbilityDefinition ability = Ability(cooldown: 10f, cost: 80f);
        var caster = new AbilityCaster(new[] { ability }, 100f);
        caster.TryCast(ability.Id, 0.0, 0f, out _);

        AbilityStatus status = AbilityStatusResolver.Resolve(caster, ability, 5.0);

        Assert.Equal(AbilityReadiness.OnCooldown, status.Readiness);
    }

    [Fact]
    public void Resolve_NullArguments_Throw()
    {
        AbilityDefinition ability = Ability();
        var caster = new AbilityCaster(new[] { ability }, 100f);

        Assert.Throws<ArgumentNullException>(() => AbilityStatusResolver.Resolve(null!, ability, 0.0));
        Assert.Throws<ArgumentNullException>(() => AbilityStatusResolver.Resolve(caster, null!, 0.0));
    }
}
