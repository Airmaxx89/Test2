using System;
using Aethermoor.Gameplay.Progression;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ExperienceTrackerTests
{
    // Lineare Kurve (Exponent 1) für nachvollziehbare Zahlen: Level n -> n+1 kostet 100·n.
    private static ExperienceTracker Linear(int maxLevel = 55)
        => new(baseXpPerLevel: 100f, exponent: 1f, maxLevel: maxLevel);

    [Fact]
    public void New_StartsAtLevelOne_WithEmptyBar()
    {
        ExperienceTracker tracker = Linear();

        Assert.Equal(1, tracker.Level);
        Assert.Equal(0f, tracker.CurrentXp);
        Assert.Equal(100f, tracker.XpToNextLevel);
        Assert.Equal(0f, tracker.ProgressFraction);
        Assert.False(tracker.IsMaxLevel);
    }

    [Fact]
    public void GrantXp_Accumulates_WithoutLevelUp()
    {
        ExperienceTracker tracker = Linear();

        int ups = tracker.GrantXp(50f);

        Assert.Equal(0, ups);
        Assert.Equal(1, tracker.Level);
        Assert.Equal(50f, tracker.CurrentXp);
        Assert.Equal(0.5f, tracker.ProgressFraction, precision: 5);
    }

    [Fact]
    public void LevelUp_CarriesOverflow()
    {
        ExperienceTracker tracker = Linear();

        int ups = tracker.GrantXp(130f); // 100 für Level 2, 30 Überschuss

        Assert.Equal(1, ups);
        Assert.Equal(2, tracker.Level);
        Assert.Equal(30f, tracker.CurrentXp);
        Assert.Equal(200f, tracker.XpToNextLevel); // linear: Level 2 kostet 200
    }

    [Fact]
    public void SingleGrant_CanSpanMultipleLevels()
    {
        ExperienceTracker tracker = Linear();

        // 100 (Lv1->2) + 200 (Lv2->3) + 50 Rest = 350.
        int ups = tracker.GrantXp(350f);

        Assert.Equal(2, ups);
        Assert.Equal(3, tracker.Level);
        Assert.Equal(50f, tracker.CurrentXp);
    }

    [Fact]
    public void Curve_IsMonotonicallyIncreasing()
    {
        var tracker = new ExperienceTracker(); // Standardkurve (Exponent 1,5)

        Assert.True(tracker.XpRequiredForLevel(2) > tracker.XpRequiredForLevel(1));
        Assert.True(tracker.XpRequiredForLevel(10) > tracker.XpRequiredForLevel(9));
        Assert.True(tracker.XpRequiredForLevel(54) > tracker.XpRequiredForLevel(53));
    }

    [Fact]
    public void AtMaxLevel_XpIsDiscarded()
    {
        ExperienceTracker tracker = Linear(maxLevel: 2);

        tracker.GrantXp(150f); // 100 -> Level 2 (Cap), 50 verfallen

        Assert.True(tracker.IsMaxLevel);
        Assert.Equal(2, tracker.Level);
        Assert.Equal(0f, tracker.CurrentXp);
        Assert.Equal(0f, tracker.XpToNextLevel);
        Assert.Equal(1f, tracker.ProgressFraction);

        Assert.Equal(0, tracker.GrantXp(999f)); // weitere XP wirkungslos
        Assert.Equal(0f, tracker.CurrentXp);
    }

    [Fact]
    public void GrantXp_Negative_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Linear().GrantXp(-1f));
    }

    [Theory]
    [InlineData(0f, 1.5f, 55)]   // Basis nicht positiv
    [InlineData(100f, 0.5f, 55)] // Exponent < 1
    [InlineData(100f, 1.5f, 1)]  // Cap < 2
    public void Constructor_InvalidArguments_Throw(float baseXp, float exponent, int maxLevel)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => new ExperienceTracker(baseXp, exponent, maxLevel));
    }
}
