using System;
using System.Collections.Generic;
using Aethermoor.Gameplay.Zones;
using Xunit;

namespace Aethermoor.Tests;

public sealed class RespawnSchedulerTests
{
    [Fact]
    public void ScheduledSpawn_IsPending()
    {
        var scheduler = new RespawnScheduler();
        scheduler.Schedule(1, now: 100.0, delaySeconds: 20.0);

        Assert.True(scheduler.IsPending(1));
        Assert.False(scheduler.IsPending(2));
    }

    [Fact]
    public void CollectDue_BeforeDeadline_ReturnsNothing()
    {
        var scheduler = new RespawnScheduler();
        scheduler.Schedule(1, 100.0, 20.0);
        var due = new List<int>();

        scheduler.CollectDue(119.9, due);

        Assert.Empty(due);
        Assert.True(scheduler.IsPending(1));
    }

    [Fact]
    public void CollectDue_AtDeadline_ReturnsAndRemoves()
    {
        var scheduler = new RespawnScheduler();
        scheduler.Schedule(1, 100.0, 20.0);
        var due = new List<int>();

        scheduler.CollectDue(120.0, due);

        Assert.Equal(new[] { 1 }, due);
        Assert.False(scheduler.IsPending(1));

        due.Clear();
        scheduler.CollectDue(121.0, due);
        Assert.Empty(due); // nicht doppelt geliefert
    }

    [Fact]
    public void CollectDue_MixedDeadlines_ReturnsOnlyDue()
    {
        var scheduler = new RespawnScheduler();
        scheduler.Schedule(1, 100.0, 10.0); // fällig ab 110
        scheduler.Schedule(2, 100.0, 30.0); // fällig ab 130
        var due = new List<int>();

        scheduler.CollectDue(115.0, due);

        Assert.Equal(new[] { 1 }, due);
        Assert.True(scheduler.IsPending(2));
    }

    [Fact]
    public void Reschedule_OverwritesDeadline()
    {
        var scheduler = new RespawnScheduler();
        scheduler.Schedule(1, 100.0, 10.0);
        scheduler.Schedule(1, 100.0, 50.0); // überschreibt -> fällig ab 150
        var due = new List<int>();

        scheduler.CollectDue(120.0, due);
        Assert.Empty(due);

        scheduler.CollectDue(150.0, due);
        Assert.Equal(new[] { 1 }, due);
    }

    [Fact]
    public void CollectDue_AppendsWithoutTouchingExistingListEntries()
    {
        var scheduler = new RespawnScheduler();
        scheduler.Schedule(7, 100.0, 5.0);
        var due = new List<int> { 99 }; // Fremdinhalt des Aufrufers

        scheduler.CollectDue(110.0, due);

        Assert.Equal(new[] { 99, 7 }, due);
    }

    [Theory]
    [InlineData(0.0)]
    [InlineData(-3.0)]
    public void Schedule_NonPositiveDelay_Throws(double delay)
    {
        var scheduler = new RespawnScheduler();
        Assert.Throws<ArgumentOutOfRangeException>(() => scheduler.Schedule(1, 0.0, delay));
    }

    [Fact]
    public void CollectDue_NullList_Throws()
    {
        var scheduler = new RespawnScheduler();
        Assert.Throws<ArgumentNullException>(() => scheduler.CollectDue(0.0, null!));
    }
}
