using System;
using System.Collections.Generic;
using System.Numerics;
using Aethermoor.Gameplay.Targeting;
using Xunit;

namespace Aethermoor.Tests;

public sealed class TargetTrackerTests
{
    private static readonly Vector2 Origin = Vector2.Zero;
    private static readonly Vector2 FacingRight = new(1f, 0f);

    private static TargetTracker Tracker()
        => new(new SmartTargetSelector(maxRange: 600f, coneHalfAngleDegrees: 120f, distanceWeight: 1f));

    private static List<TargetCandidate> Candidates(params TargetCandidate[] c) => new(c);

    private static TargetCandidate At(long id, float x) => new(id, new Vector2(x, 0f), true);

    [Fact]
    public void NoCandidates_HasNoTarget_AndReportsNoChange()
    {
        TargetTracker tracker = Tracker();

        bool changed = tracker.Update(Origin, FacingRight, Candidates());

        Assert.False(changed);
        Assert.Null(tracker.CurrentTargetId);
    }

    [Fact]
    public void FirstCandidate_BecomesTarget_AndReportsChange()
    {
        TargetTracker tracker = Tracker();

        bool changed = tracker.Update(Origin, FacingRight, Candidates(At(7, 100f)));

        Assert.True(changed);
        Assert.Equal(7, tracker.CurrentTargetId);
    }

    [Fact]
    public void SameTargetNextFrame_ReportsNoChange()
    {
        TargetTracker tracker = Tracker();
        tracker.Update(Origin, FacingRight, Candidates(At(7, 100f)));

        bool changed = tracker.Update(Origin, FacingRight, Candidates(At(7, 110f)));

        Assert.False(changed);
        Assert.Equal(7, tracker.CurrentTargetId);
    }

    [Fact]
    public void CloserCandidateAppears_SwitchesTarget_AndReportsChange()
    {
        TargetTracker tracker = Tracker();
        tracker.Update(Origin, FacingRight, Candidates(At(7, 200f)));

        bool changed = tracker.Update(Origin, FacingRight, Candidates(At(7, 200f), At(9, 50f)));

        Assert.True(changed);
        Assert.Equal(9, tracker.CurrentTargetId);
    }

    [Fact]
    public void TargetLeaves_SelectsRemaining_AndReportsChange()
    {
        TargetTracker tracker = Tracker();
        tracker.Update(Origin, FacingRight, Candidates(At(9, 50f), At(7, 200f)));
        Assert.Equal(9, tracker.CurrentTargetId);

        bool changed = tracker.Update(Origin, FacingRight, Candidates(At(7, 200f)));

        Assert.True(changed);
        Assert.Equal(7, tracker.CurrentTargetId);
    }

    [Fact]
    public void AllCandidatesGone_ClearsTarget_AndReportsChange()
    {
        TargetTracker tracker = Tracker();
        tracker.Update(Origin, FacingRight, Candidates(At(7, 100f)));

        bool changed = tracker.Update(Origin, FacingRight, Candidates());

        Assert.True(changed);
        Assert.Null(tracker.CurrentTargetId);
    }

    [Fact]
    public void Clear_WithTarget_ReportsChange_ThenIdempotent()
    {
        TargetTracker tracker = Tracker();
        tracker.Update(Origin, FacingRight, Candidates(At(7, 100f)));

        Assert.True(tracker.Clear());
        Assert.Null(tracker.CurrentTargetId);
        Assert.False(tracker.Clear());
    }

    [Fact]
    public void Constructor_NullSelector_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new TargetTracker(null!));
    }
}
