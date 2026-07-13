using System;
using Aethermoor.Gameplay.Combat;
using Xunit;

namespace Aethermoor.Tests;

public sealed class HealthPoolTests
{
    [Fact]
    public void New_StartsFull()
    {
        var pool = new HealthPool(120f);

        Assert.Equal(120f, pool.Current);
        Assert.Equal(1f, pool.Fraction);
        Assert.False(pool.IsDead);
    }

    [Fact]
    public void ApplyDamage_ReducesHealth_AndReportsAppliedAmount()
    {
        var pool = new HealthPool(100f);

        float applied = pool.ApplyDamage(30f);

        Assert.Equal(30f, applied);
        Assert.Equal(70f, pool.Current);
        Assert.Equal(0.7f, pool.Fraction, precision: 5);
    }

    [Fact]
    public void KillingBlow_ClampsAtZero_AndReportsOnlyActualDamage()
    {
        var pool = new HealthPool(100f);
        pool.ApplyDamage(90f);

        float applied = pool.ApplyDamage(500f); // Overkill

        Assert.Equal(10f, applied);
        Assert.Equal(0f, pool.Current);
        Assert.True(pool.IsDead);
    }

    [Fact]
    public void DeadTarget_TakesNoFurtherDamage()
    {
        var pool = new HealthPool(50f);
        pool.ApplyDamage(50f);

        Assert.Equal(0f, pool.ApplyDamage(10f));
        Assert.True(pool.IsDead);
    }

    [Fact]
    public void Heal_RestoresHealth_ClampedAtMax()
    {
        var pool = new HealthPool(100f);
        pool.ApplyDamage(40f);

        float healed = pool.Heal(500f);

        Assert.Equal(40f, healed);
        Assert.Equal(100f, pool.Current);
    }

    [Fact]
    public void DeadTarget_CannotBeHealed()
    {
        var pool = new HealthPool(50f);
        pool.ApplyDamage(50f);

        Assert.Equal(0f, pool.Heal(25f));
        Assert.True(pool.IsDead);
    }

    [Fact]
    public void NegativeAmounts_Throw()
    {
        var pool = new HealthPool(100f);

        Assert.Throws<ArgumentOutOfRangeException>(() => pool.ApplyDamage(-1f));
        Assert.Throws<ArgumentOutOfRangeException>(() => pool.Heal(-1f));
    }

    [Theory]
    [InlineData(0f)]
    [InlineData(-50f)]
    public void Constructor_NonPositiveMax_Throws(float max)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new HealthPool(max));
    }
}
