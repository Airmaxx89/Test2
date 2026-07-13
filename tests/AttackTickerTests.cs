using System;
using Aethermoor.Gameplay.Combat;
using Xunit;

namespace Aethermoor.Tests;

public sealed class AttackTickerTests
{
    [Fact]
    public void FirstAttack_IsImmediatelyAllowed()
    {
        var ticker = new AttackTicker(1.5);
        Assert.True(ticker.TryAttack(100.0));
    }

    [Fact]
    public void SecondAttack_IsGatedUntilIntervalElapsed()
    {
        var ticker = new AttackTicker(1.5);
        ticker.TryAttack(100.0);

        Assert.False(ticker.TryAttack(100.5));
        Assert.False(ticker.TryAttack(101.4));
    }

    [Fact]
    public void Attack_AllowedExactlyAtIntervalBoundary()
    {
        var ticker = new AttackTicker(1.5);
        ticker.TryAttack(100.0);

        Assert.True(ticker.TryAttack(101.5));
    }

    [Fact]
    public void GatedAttempts_DoNotDelayTheNextWindow()
    {
        var ticker = new AttackTicker(1.0);
        ticker.TryAttack(100.0);
        ticker.TryAttack(100.9); // abgelehnt — darf das Fenster nicht verschieben

        Assert.True(ticker.TryAttack(101.0));
    }

    [Fact]
    public void Reset_AllowsImmediateAttack()
    {
        var ticker = new AttackTicker(10.0);
        ticker.TryAttack(100.0);

        ticker.Reset();

        Assert.True(ticker.TryAttack(100.1));
    }

    [Theory]
    [InlineData(0.0)]
    [InlineData(-1.0)]
    public void Constructor_NonPositiveInterval_Throws(double interval)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new AttackTicker(interval));
    }
}
