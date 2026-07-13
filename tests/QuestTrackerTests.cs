using System;
using Aethermoor.Gameplay.Quests;
using Xunit;

namespace Aethermoor.Tests;

public sealed class QuestTrackerTests
{
    private const string Target = "silberwald.wegelagerer";

    private static QuestDefinition Quest(int required = 3)
        => new("morgenau.plage", "Plage am Wegesrand", Target, required);

    [Fact]
    public void New_IsNotStarted()
    {
        var tracker = new QuestTracker(Quest());

        Assert.Equal(QuestState.NotStarted, tracker.State);
        Assert.Equal(0, tracker.CurrentCount);
    }

    [Fact]
    public void KillsBeforeStart_DoNotCount()
    {
        var tracker = new QuestTracker(Quest());

        Assert.False(tracker.RegisterKill(Target));
        Assert.Equal(0, tracker.CurrentCount);
    }

    [Fact]
    public void Start_Activates()
    {
        var tracker = new QuestTracker(Quest());
        tracker.Start();

        Assert.Equal(QuestState.Active, tracker.State);
    }

    [Fact]
    public void Start_Twice_Throws()
    {
        var tracker = new QuestTracker(Quest());
        tracker.Start();

        Assert.Throws<InvalidOperationException>(tracker.Start);
    }

    [Fact]
    public void MatchingKills_Count()
    {
        var tracker = new QuestTracker(Quest(required: 3));
        tracker.Start();

        Assert.True(tracker.RegisterKill(Target));
        Assert.True(tracker.RegisterKill(Target));
        Assert.Equal(2, tracker.CurrentCount);
        Assert.Equal(QuestState.Active, tracker.State);
    }

    [Fact]
    public void WrongEnemy_DoesNotCount()
    {
        var tracker = new QuestTracker(Quest());
        tracker.Start();

        Assert.False(tracker.RegisterKill("anderes.monster"));
        Assert.Equal(0, tracker.CurrentCount);
    }

    [Fact]
    public void ReachingRequiredCount_Completes()
    {
        var tracker = new QuestTracker(Quest(required: 2));
        tracker.Start();
        tracker.RegisterKill(Target);

        Assert.True(tracker.RegisterKill(Target));
        Assert.Equal(QuestState.Completed, tracker.State);
        Assert.Equal(2, tracker.CurrentCount);
    }

    [Fact]
    public void KillsAfterCompletion_AreIgnored()
    {
        var tracker = new QuestTracker(Quest(required: 1));
        tracker.Start();
        tracker.RegisterKill(Target);

        Assert.False(tracker.RegisterKill(Target));
        Assert.Equal(1, tracker.CurrentCount);
    }

    [Fact]
    public void Constructor_NullDefinition_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new QuestTracker(null!));
    }

    [Theory]
    [InlineData("", Target, 3)]
    [InlineData("quest.id", "", 3)]
    [InlineData("quest.id", Target, 0)]
    [InlineData("quest.id", Target, -1)]
    public void Constructor_InvalidDefinition_Throws(string id, string target, int required)
    {
        Assert.Throws<ArgumentException>(
            () => new QuestTracker(new QuestDefinition(id, "Titel", target, required)));
    }
}
