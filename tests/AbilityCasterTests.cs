using System;
using Aethermoor.Gameplay.Abilities;
using Xunit;

namespace Aethermoor.Tests;

public sealed class AbilityCasterTests
{
    private const float MaxMana = 100f;

    private static AbilityDefinition Strike(
        string id = "test.schlag",
        float cooldown = 6f,
        float cost = 20f,
        float range = 80f)
        => new(id, "Schlag", cooldown, cost, range, AbilityEffectType.Damage, 35f);

    private static AbilityDefinition SelfHeal()
        => new("test.heilung", "Heilung", 30f, 40f, 0f, AbilityEffectType.Heal, 120f);

    private static AbilityCaster Caster(params AbilityDefinition[] abilities)
        => new(abilities, MaxMana);

    [Fact]
    public void TryCast_Success_SpendsResourceAndStartsCooldown()
    {
        AbilityCaster caster = Caster(Strike());

        bool result = caster.TryCast("test.schlag", now: 10.0, distanceToTarget: 50f, out CastFailureReason reason);

        Assert.True(result);
        Assert.Equal(CastFailureReason.None, reason);
        Assert.Equal(MaxMana - 20f, caster.CurrentResource);
        Assert.Equal(6.0, caster.GetCooldownRemaining("test.schlag", 10.0), precision: 5);
    }

    [Fact]
    public void TryCast_UnknownAbility_Fails()
    {
        AbilityCaster caster = Caster(Strike());

        Assert.False(caster.TryCast("gibt.es.nicht", 0.0, 0f, out CastFailureReason reason));
        Assert.Equal(CastFailureReason.UnknownAbility, reason);
    }

    [Fact]
    public void TryCast_DuringCooldown_Fails_AndBecomesReadyExactlyAtEnd()
    {
        AbilityCaster caster = Caster(Strike(cooldown: 6f, cost: 10f));
        caster.TryCast("test.schlag", 0.0, 10f, out _);

        Assert.False(caster.TryCast("test.schlag", 5.9, 10f, out CastFailureReason during));
        Assert.Equal(CastFailureReason.OnCooldown, during);

        // Exakt zum Ablauf wieder bereit.
        Assert.True(caster.TryCast("test.schlag", 6.0, 10f, out CastFailureReason after));
        Assert.Equal(CastFailureReason.None, after);
    }

    [Fact]
    public void TryCast_InsufficientResource_Fails()
    {
        AbilityCaster caster = Caster(Strike(cooldown: 0f, cost: 60f));
        caster.TryCast("test.schlag", 0.0, 10f, out _); // 100 -> 40

        Assert.False(caster.TryCast("test.schlag", 1.0, 10f, out CastFailureReason reason));
        Assert.Equal(CastFailureReason.InsufficientResource, reason);
    }

    [Fact]
    public void TryCast_OutOfRange_Fails_WithoutSpendingResource()
    {
        AbilityCaster caster = Caster(Strike(range: 80f));

        Assert.False(caster.TryCast("test.schlag", 0.0, 81f, out CastFailureReason reason));
        Assert.Equal(CastFailureReason.OutOfRange, reason);
        Assert.Equal(MaxMana, caster.CurrentResource); // Ablehnung kostet nichts
    }

    [Fact]
    public void TryCast_RangeZero_SkipsDistanceCheck()
    {
        AbilityCaster caster = Caster(SelfHeal());

        // Riesige "Distanz" ist irrelevant: Range 0 = Selbstwirkung/ungezielt.
        Assert.True(caster.TryCast("test.heilung", 0.0, 99999f, out CastFailureReason reason));
        Assert.Equal(CastFailureReason.None, reason);
    }

    [Fact]
    public void GetCooldownRemaining_CountsDown()
    {
        AbilityCaster caster = Caster(Strike(cooldown: 10f));
        caster.TryCast("test.schlag", 100.0, 10f, out _);

        Assert.Equal(10.0, caster.GetCooldownRemaining("test.schlag", 100.0), precision: 5);
        Assert.Equal(4.0, caster.GetCooldownRemaining("test.schlag", 106.0), precision: 5);
        Assert.Equal(0.0, caster.GetCooldownRemaining("test.schlag", 110.0));
        Assert.Equal(0.0, caster.GetCooldownRemaining("test.schlag", 200.0));
    }

    [Fact]
    public void GetCooldownRemaining_UnknownOrNeverCast_IsZero()
    {
        AbilityCaster caster = Caster(Strike());

        Assert.Equal(0.0, caster.GetCooldownRemaining("test.schlag", 0.0));
        Assert.Equal(0.0, caster.GetCooldownRemaining("unbekannt", 0.0));
    }

    [Fact]
    public void RestoreResource_ClampsAtMaximum()
    {
        AbilityCaster caster = Caster(Strike(cooldown: 0f, cost: 30f));
        caster.TryCast("test.schlag", 0.0, 10f, out _); // 100 -> 70

        caster.RestoreResource(500f);

        Assert.Equal(MaxMana, caster.CurrentResource);
    }

    [Fact]
    public void RestoreResource_Negative_Throws()
    {
        AbilityCaster caster = Caster(Strike());
        Assert.Throws<ArgumentOutOfRangeException>(() => caster.RestoreResource(-1f));
    }

    [Fact]
    public void Constructor_DuplicateIds_Throw()
    {
        Assert.Throws<ArgumentException>(
            () => Caster(Strike("dupe"), Strike("dupe")));
    }

    [Fact]
    public void Constructor_InvalidDefinitionValues_Throw()
    {
        Assert.Throws<ArgumentException>(() => Caster(Strike(cooldown: -1f)));
        Assert.Throws<ArgumentException>(() => Caster(Strike(cost: -5f)));
        Assert.Throws<ArgumentException>(() => Caster(Strike(id: "  ")));
    }

    [Theory]
    [InlineData(0f)]
    [InlineData(-10f)]
    public void Constructor_NonPositiveMaxResource_Throws(float maxResource)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => new AbilityCaster(new[] { Strike() }, maxResource));
    }

    [Fact]
    public void Abilities_ExposesAllKnownDefinitions()
    {
        AbilityCaster caster = Caster(Strike(), SelfHeal());
        Assert.Equal(2, caster.Abilities.Count);
    }
}
