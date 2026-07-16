using System.Collections.Generic;
using Aethermoor.Gameplay.Targeting;
using Aethermoor.Networking.Protocol;
using Aethermoor.Networking.Replication;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ServerEnemyTargetsTests
{
    private static ServerEnemyReplicator Replicator(params EnemySnapshot[] enemies)
    {
        var replicator = new ServerEnemyReplicator(interpolationDelaySeconds: 0.0);
        replicator.Apply(1.0, enemies);
        return replicator;
    }

    [Fact]
    public void Collect_ProducesCandidateWithSidAndPosition()
    {
        ServerEnemyReplicator enemies = Replicator(new EnemySnapshot(3, 100f, 200f, 80f));
        var into = new List<TargetCandidate>();

        ServerEnemyTargets.Collect(enemies, 1.0, into);

        Assert.Single(into);
        Assert.Equal(3, into[0].Id);
        Assert.Equal(100f, into[0].Position.X);
        Assert.Equal(200f, into[0].Position.Y);
        Assert.True(into[0].IsTargetable);
    }

    [Fact]
    public void Collect_MarksDeadEnemiesNotTargetable()
    {
        ServerEnemyReplicator enemies = Replicator(
            new EnemySnapshot(0, 10f, 0f, 100f),
            new EnemySnapshot(1, 20f, 0f, 0f));
        var into = new List<TargetCandidate>();

        ServerEnemyTargets.Collect(enemies, 1.0, into);

        Assert.Equal(2, into.Count);
        TargetCandidate dead = into.Find(c => c.Id == 1);
        Assert.False(dead.IsTargetable);
    }

    [Fact]
    public void Collect_AppendsToExistingList()
    {
        ServerEnemyReplicator enemies = Replicator(new EnemySnapshot(0, 1f, 2f, 50f));
        var into = new List<TargetCandidate> { new(99, System.Numerics.Vector2.Zero, true) };

        ServerEnemyTargets.Collect(enemies, 1.0, into);

        Assert.Equal(2, into.Count);
        Assert.Equal(99, into[0].Id);
    }

    [Fact]
    public void SelectedServerEnemy_FeedsTargetTracker()
    {
        // Integration: Server-Gegner -> Kandidaten -> Auswahl liefert die Spawn-ID als Ziel.
        ServerEnemyReplicator enemies = Replicator(
            new EnemySnapshot(0, 300f, 0f, 100f),
            new EnemySnapshot(1, 80f, 0f, 100f));
        var into = new List<TargetCandidate>();
        ServerEnemyTargets.Collect(enemies, 1.0, into);

        var tracker = new TargetTracker(
            new SmartTargetSelector(600f, 120f, distanceWeight: 1f));
        tracker.Update(System.Numerics.Vector2.Zero, new System.Numerics.Vector2(1f, 0f), into);

        Assert.Equal(1, tracker.CurrentTargetId); // näher -> gewählt; Ziel-ID == Spawn-ID
    }
}
