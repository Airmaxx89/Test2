using System;
using Aethermoor.Core.Scenes;
using Xunit;

namespace Aethermoor.Tests;

public sealed class SceneLoadTrackerTests
{
    private const string Path = "res://scenes/MainMenu.tscn";

    private static SceneLoadTracker Started()
    {
        var tracker = new SceneLoadTracker();
        tracker.Begin(Path);
        return tracker;
    }

    [Fact]
    public void New_IsIdle()
    {
        var tracker = new SceneLoadTracker();
        Assert.Equal(SceneLoadPhase.Idle, tracker.Phase);
        Assert.Null(tracker.TargetPath);
        Assert.Equal(0f, tracker.Progress);
    }

    [Fact]
    public void Begin_EntersInProgress_WithTargetAndZeroProgress()
    {
        var tracker = Started();
        Assert.Equal(SceneLoadPhase.InProgress, tracker.Phase);
        Assert.Equal(Path, tracker.TargetPath);
        Assert.Equal(0f, tracker.Progress);
    }

    [Theory]
    [InlineData("")]
    [InlineData(null)]
    public void Begin_EmptyPath_Throws(string? path)
    {
        var tracker = new SceneLoadTracker();
        // Leerstring -> ArgumentException, null -> ArgumentNullException (abgeleitet).
        Assert.ThrowsAny<ArgumentException>(() => tracker.Begin(path!));
    }

    [Fact]
    public void Begin_WhileInProgress_Throws()
    {
        var tracker = Started();
        Assert.Throws<InvalidOperationException>(() => tracker.Begin("res://other.tscn"));
    }

    [Fact]
    public void Report_BeforeBegin_Throws()
    {
        var tracker = new SceneLoadTracker();
        Assert.Throws<InvalidOperationException>(
            () => tracker.Report(SceneLoadStatus.InProgress, 0.5f));
    }

    [Fact]
    public void Report_InProgress_UpdatesProgress()
    {
        var tracker = Started();
        SceneLoadPhase phase = tracker.Report(SceneLoadStatus.InProgress, 0.42f);

        Assert.Equal(SceneLoadPhase.InProgress, phase);
        Assert.Equal(0.42f, tracker.Progress, precision: 5);
    }

    [Fact]
    public void Report_ClampsProgressToUnitRange()
    {
        var tracker = Started();

        tracker.Report(SceneLoadStatus.InProgress, 2.5f);
        Assert.Equal(1f, tracker.Progress);

        // Bereits geklemmt/monoton: ein negativer Wert darf nicht zurückfallen.
        tracker.Report(SceneLoadStatus.InProgress, -1f);
        Assert.Equal(1f, tracker.Progress);
    }

    [Fact]
    public void Report_ProgressIsMonotonic_DoesNotRegress()
    {
        var tracker = Started();

        tracker.Report(SceneLoadStatus.InProgress, 0.6f);
        tracker.Report(SceneLoadStatus.InProgress, 0.3f); // niedriger -> ignoriert

        Assert.Equal(0.6f, tracker.Progress, precision: 5);
    }

    [Fact]
    public void Report_Loaded_SucceedsWithFullProgress()
    {
        var tracker = Started();
        SceneLoadPhase phase = tracker.Report(SceneLoadStatus.Loaded, 0.9f);

        Assert.Equal(SceneLoadPhase.Succeeded, phase);
        Assert.Equal(1f, tracker.Progress);
    }

    [Theory]
    [InlineData(SceneLoadStatus.Failed)]
    [InlineData(SceneLoadStatus.InvalidResource)]
    public void Report_FailureStatuses_EnterFailed(SceneLoadStatus status)
    {
        var tracker = Started();
        SceneLoadPhase phase = tracker.Report(status, 0.5f);

        Assert.Equal(SceneLoadPhase.Failed, phase);
    }

    [Fact]
    public void Report_AfterTerminalPhase_Throws()
    {
        var tracker = Started();
        tracker.Report(SceneLoadStatus.Loaded, 1f); // -> Succeeded (Endzustand)

        Assert.Throws<InvalidOperationException>(
            () => tracker.Report(SceneLoadStatus.InProgress, 0.5f));
    }

    [Fact]
    public void Reset_ReturnsToIdle()
    {
        var tracker = Started();
        tracker.Report(SceneLoadStatus.Loaded, 1f);

        tracker.Reset();

        Assert.Equal(SceneLoadPhase.Idle, tracker.Phase);
        Assert.Null(tracker.TargetPath);
        Assert.Equal(0f, tracker.Progress);
    }

    [Fact]
    public void Reset_AllowsANewLoad()
    {
        var tracker = Started();
        tracker.Report(SceneLoadStatus.Loaded, 1f);
        tracker.Reset();

        tracker.Begin("res://scenes/Other.tscn");

        Assert.Equal(SceneLoadPhase.InProgress, tracker.Phase);
        Assert.Equal("res://scenes/Other.tscn", tracker.TargetPath);
    }
}
