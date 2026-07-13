using System;
using Aethermoor.Gameplay.Abilities;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ComboTrackerTests
{
    private const long TargetA = 1;
    private const long TargetB = 2;
    private const string Marker = "wappenbruch";

    [Fact]
    public void AppliedMarker_IsActive_WithinDuration()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, now: 100.0, durationSeconds: 8.0);

        Assert.True(tracker.HasMarker(TargetA, Marker, 100.0));
        Assert.True(tracker.HasMarker(TargetA, Marker, 107.9));
    }

    [Fact]
    public void Marker_ExpiresExactlyAtDeadline()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);

        Assert.False(tracker.HasMarker(TargetA, Marker, 108.0));
    }

    [Fact]
    public void UnknownMarkerOrTarget_IsInactive()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);

        Assert.False(tracker.HasMarker(TargetA, "anderer", 101.0));
        Assert.False(tracker.HasMarker(TargetB, Marker, 101.0));
    }

    [Fact]
    public void TryConsume_RemovesActiveMarker_OnlyOnce()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);

        Assert.True(tracker.TryConsumeMarker(TargetA, Marker, 101.0));
        Assert.False(tracker.TryConsumeMarker(TargetA, Marker, 101.1)); // ein Finisher pro Marker
        Assert.False(tracker.HasMarker(TargetA, Marker, 101.1));
    }

    [Fact]
    public void TryConsume_ExpiredMarker_Fails()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);

        Assert.False(tracker.TryConsumeMarker(TargetA, Marker, 120.0));
    }

    [Fact]
    public void Reapply_RefreshesDuration()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);
        tracker.ApplyMarker(TargetA, Marker, 106.0, 8.0); // erneuert -> gültig bis 114

        Assert.True(tracker.HasMarker(TargetA, Marker, 113.0));
    }

    [Fact]
    public void Targets_AreIndependent()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);
        tracker.ApplyMarker(TargetB, Marker, 100.0, 8.0);

        tracker.TryConsumeMarker(TargetA, Marker, 101.0);

        Assert.True(tracker.HasMarker(TargetB, Marker, 101.0));
    }

    [Fact]
    public void ClearTarget_RemovesAllMarkersOfThatTargetOnly()
    {
        var tracker = new ComboTracker();
        tracker.ApplyMarker(TargetA, Marker, 100.0, 8.0);
        tracker.ApplyMarker(TargetA, "blutung", 100.0, 8.0);
        tracker.ApplyMarker(TargetB, Marker, 100.0, 8.0);

        tracker.ClearTarget(TargetA);

        Assert.False(tracker.HasMarker(TargetA, Marker, 101.0));
        Assert.False(tracker.HasMarker(TargetA, "blutung", 101.0));
        Assert.True(tracker.HasMarker(TargetB, Marker, 101.0));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void ApplyMarker_EmptyName_Throws(string marker)
    {
        var tracker = new ComboTracker();
        Assert.Throws<ArgumentException>(() => tracker.ApplyMarker(TargetA, marker, 0.0, 1.0));
    }

    [Theory]
    [InlineData(0.0)]
    [InlineData(-5.0)]
    public void ApplyMarker_NonPositiveDuration_Throws(double duration)
    {
        var tracker = new ComboTracker();
        Assert.Throws<ArgumentOutOfRangeException>(
            () => tracker.ApplyMarker(TargetA, Marker, 0.0, duration));
    }
}
