using System;
using Aethermoor.Networking.Connection;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ReconnectBackoffTests
{
    // Zufallsquelle 0,5 = kein Jitter -> deterministische Erwartungswerte.
    private static ReconnectBackoff NoJitter(int maxAttempts = 0) => new(
        baseDelay: TimeSpan.FromSeconds(1),
        maxDelay: TimeSpan.FromSeconds(30),
        multiplier: 2.0,
        jitterRatio: 0.2,
        maxAttempts: maxAttempts,
        nextUnitRandom: () => 0.5);

    [Fact]
    public void FirstAttempt_UsesBaseDelay()
    {
        Assert.Equal(1.0, NoJitter().NextDelay(1).TotalSeconds, precision: 6);
    }

    [Fact]
    public void Delay_GrowsExponentially()
    {
        var backoff = NoJitter();

        Assert.Equal(1.0, backoff.NextDelay(1).TotalSeconds, precision: 6);
        Assert.Equal(2.0, backoff.NextDelay(2).TotalSeconds, precision: 6);
        Assert.Equal(4.0, backoff.NextDelay(3).TotalSeconds, precision: 6);
        Assert.Equal(8.0, backoff.NextDelay(4).TotalSeconds, precision: 6);
    }

    [Fact]
    public void Delay_IsCappedAtMax()
    {
        var backoff = NoJitter();

        // 2^9 = 512 s, gedeckelt auf 30 s.
        Assert.Equal(30.0, backoff.NextDelay(10).TotalSeconds, precision: 6);
    }

    [Fact]
    public void Jitter_LowerBound_WhenRandomIsZero()
    {
        var backoff = new ReconnectBackoff(
            TimeSpan.FromSeconds(10), TimeSpan.FromSeconds(100),
            multiplier: 2.0, jitterRatio: 0.2, nextUnitRandom: () => 0.0);

        // 10 s · (1 - 0,2) = 8 s
        Assert.Equal(8.0, backoff.NextDelay(1).TotalSeconds, precision: 6);
    }

    [Fact]
    public void Jitter_UpperBound_WhenRandomIsOne()
    {
        var backoff = new ReconnectBackoff(
            TimeSpan.FromSeconds(10), TimeSpan.FromSeconds(100),
            multiplier: 2.0, jitterRatio: 0.2, nextUnitRandom: () => 1.0);

        // 10 s · (1 + 0,2) = 12 s
        Assert.Equal(12.0, backoff.NextDelay(1).TotalSeconds, precision: 6);
    }

    [Fact]
    public void Jitter_NeverExceedsMax()
    {
        var backoff = new ReconnectBackoff(
            TimeSpan.FromSeconds(30), TimeSpan.FromSeconds(30),
            multiplier: 2.0, jitterRatio: 0.5, nextUnitRandom: () => 1.0);

        // capped = 30, +50 % waere 45 -> auf maxDelay 30 geklemmt.
        Assert.Equal(30.0, backoff.NextDelay(1).TotalSeconds, precision: 6);
    }

    [Fact]
    public void ShouldRetry_UnlimitedWhenMaxAttemptsZero()
    {
        var backoff = NoJitter(maxAttempts: 0);
        Assert.True(backoff.ShouldRetry(1));
        Assert.True(backoff.ShouldRetry(1000));
    }

    [Fact]
    public void ShouldRetry_RespectsMaxAttempts()
    {
        var backoff = NoJitter(maxAttempts: 3);
        Assert.True(backoff.ShouldRetry(3));
        Assert.False(backoff.ShouldRetry(4));
    }

    [Fact]
    public void NextDelay_AttemptBelowOne_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => NoJitter().NextDelay(0));
    }

    [Theory]
    [InlineData(0, 30, 2.0, 0.2, 0)]      // baseDelay = 0
    [InlineData(30, 10, 2.0, 0.2, 0)]     // maxDelay < baseDelay
    [InlineData(1, 30, 0.5, 0.2, 0)]      // multiplier < 1
    [InlineData(1, 30, 2.0, 1.5, 0)]      // jitterRatio > 1
    [InlineData(1, 30, 2.0, -0.1, 0)]     // jitterRatio < 0
    [InlineData(1, 30, 2.0, 0.2, -1)]     // maxAttempts < 0
    public void Constructor_InvalidArguments_Throw(
        double baseSec, double maxSec, double multiplier, double jitter, int maxAttempts)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new ReconnectBackoff(
            TimeSpan.FromSeconds(baseSec), TimeSpan.FromSeconds(maxSec),
            multiplier, jitter, maxAttempts));
    }
}
