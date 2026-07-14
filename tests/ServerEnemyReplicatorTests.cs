using System;
using System.Numerics;
using Aethermoor.Networking.Protocol;
using Aethermoor.Networking.Replication;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ServerEnemyReplicatorTests
{
    private static EnemySnapshot Enemy(int sid, float x, float y, float hp)
        => new(sid, x, y, hp);

    [Fact]
    public void Apply_TracksHealthAndAliveState()
    {
        var replicator = new ServerEnemyReplicator();

        replicator.Apply(1.0, new[] { Enemy(0, 100f, 200f, 85f) });

        Assert.True(replicator.IsAlive(0));
        Assert.Equal(85f, replicator.GetHealth(0));
        Assert.Contains(0, replicator.Sids);
    }

    [Fact]
    public void DeadEnemy_IsNotAlive()
    {
        var replicator = new ServerEnemyReplicator();
        replicator.Apply(1.0, new[] { Enemy(0, 100f, 200f, 0f) });

        Assert.False(replicator.IsAlive(0));
        Assert.Equal(0f, replicator.GetHealth(0));
    }

    [Fact]
    public void DeathThenRespawn_FlipsAliveState()
    {
        var replicator = new ServerEnemyReplicator();

        replicator.Apply(1.0, new[] { Enemy(0, 0f, 0f, 40f) });
        Assert.True(replicator.IsAlive(0));

        replicator.Apply(2.0, new[] { Enemy(0, 0f, 0f, 0f) }); // getötet
        Assert.False(replicator.IsAlive(0));

        replicator.Apply(3.0, new[] { Enemy(0, 0f, 0f, 120f) }); // respawnt
        Assert.True(replicator.IsAlive(0));
    }

    [Fact]
    public void SamplePosition_InterpolatesBetweenSnapshots()
    {
        var replicator = new ServerEnemyReplicator(interpolationDelaySeconds: 0.1);
        replicator.Apply(1.0, new[] { Enemy(0, 0f, 0f, 100f) });
        replicator.Apply(2.0, new[] { Enemy(0, 100f, 0f, 100f) });

        // renderTime = 1.6 - 0.1 = 1.5 -> Mitte.
        Vector2? position = replicator.SamplePosition(0, 1.6);

        Assert.NotNull(position);
        Assert.Equal(50f, position!.Value.X, precision: 4);
    }

    [Fact]
    public void MultipleEnemies_AreIndependent()
    {
        var replicator = new ServerEnemyReplicator();
        replicator.Apply(1.0, new[] { Enemy(0, 10f, 0f, 100f), Enemy(1, 20f, 0f, 0f) });

        Assert.True(replicator.IsAlive(0));
        Assert.False(replicator.IsAlive(1));
        Assert.Equal(2, replicator.Sids.Count);
    }

    [Fact]
    public void SamplePosition_UnknownSid_ReturnsNull()
    {
        var replicator = new ServerEnemyReplicator();
        Assert.Null(replicator.SamplePosition(99, 1.0));
    }

    [Fact]
    public void UnknownSid_IsNotAlive_AndHealthZero()
    {
        var replicator = new ServerEnemyReplicator();
        Assert.False(replicator.IsAlive(42));
        Assert.Equal(0f, replicator.GetHealth(42));
    }

    [Fact]
    public void Clear_RemovesAllEnemies()
    {
        var replicator = new ServerEnemyReplicator();
        replicator.Apply(1.0, new[] { Enemy(0, 0f, 0f, 100f) });

        replicator.Clear();

        Assert.Empty(replicator.Sids);
        Assert.False(replicator.IsAlive(0));
        Assert.Null(replicator.SamplePosition(0, 2.0));
    }

    [Fact]
    public void Apply_NullEnemies_Throws()
    {
        var replicator = new ServerEnemyReplicator();
        Assert.Throws<ArgumentNullException>(() => replicator.Apply(1.0, null!));
    }

    [Fact]
    public void Constructor_NegativeDelay_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new ServerEnemyReplicator(-0.1));
    }
}
