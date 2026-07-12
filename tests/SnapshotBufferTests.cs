using System;
using System.Numerics;
using Aethermoor.Networking.Replication;
using Xunit;

namespace Aethermoor.Tests;

public sealed class SnapshotBufferTests
{
    private static PositionSnapshot Snap(double t, float x, float y = 0f)
        => new(t, new Vector2(x, y));

    [Fact]
    public void EmptyBuffer_ReturnsNull()
    {
        var buffer = new SnapshotBuffer();
        Assert.Null(buffer.Sample(10.0));
    }

    [Fact]
    public void RenderTimeBetweenSnapshots_InterpolatesLinearly()
    {
        var buffer = new SnapshotBuffer(interpolationDelaySeconds: 0.1);
        buffer.Add(Snap(1.0, 0f));
        buffer.Add(Snap(2.0, 100f));

        // renderTime = 1.6 - 0.1 = 1.5 -> Mitte zwischen den Snapshots.
        Vector2? result = buffer.Sample(1.6);

        Assert.NotNull(result);
        Assert.Equal(50f, result!.Value.X, precision: 4);
    }

    [Fact]
    public void RenderTimeBeforeOldest_ClampsToOldest()
    {
        var buffer = new SnapshotBuffer(interpolationDelaySeconds: 0.1);
        buffer.Add(Snap(5.0, 42f));
        buffer.Add(Snap(6.0, 100f));

        Assert.Equal(42f, buffer.Sample(1.0)!.Value.X);
    }

    [Fact]
    public void RenderTimeAfterNewest_ClampsToNewest_NoExtrapolation()
    {
        var buffer = new SnapshotBuffer(interpolationDelaySeconds: 0.0);
        buffer.Add(Snap(1.0, 0f));
        buffer.Add(Snap(2.0, 100f));

        // Weit nach dem letzten Snapshot: klemmen statt extrapolieren.
        Assert.Equal(100f, buffer.Sample(50.0)!.Value.X);
    }

    [Fact]
    public void LateArrivingOlderSnapshot_IsSortedIn()
    {
        var buffer = new SnapshotBuffer(interpolationDelaySeconds: 0.0);
        buffer.Add(Snap(1.0, 0f));
        buffer.Add(Snap(3.0, 100f));
        buffer.Add(Snap(2.0, 60f)); // verspätet, gehört in die Mitte

        // renderTime 2.5 -> zwischen (2.0, 60) und (3.0, 100) -> 80.
        Assert.Equal(80f, buffer.Sample(2.5)!.Value.X, precision: 4);
    }

    [Fact]
    public void DuplicateTimestamp_ReplacesExistingEntry()
    {
        var buffer = new SnapshotBuffer(interpolationDelaySeconds: 0.0);
        buffer.Add(Snap(1.0, 10f));
        buffer.Add(Snap(1.0, 99f));

        Assert.Equal(1, buffer.Count);
        Assert.Equal(99f, buffer.Sample(1.0)!.Value.X);
    }

    [Fact]
    public void Capacity_DropsOldestEntries()
    {
        var buffer = new SnapshotBuffer(interpolationDelaySeconds: 0.0, capacity: 2);
        buffer.Add(Snap(1.0, 1f));
        buffer.Add(Snap(2.0, 2f));
        buffer.Add(Snap(3.0, 3f)); // verdrängt t=1.0

        Assert.Equal(2, buffer.Count);
        Assert.Equal(2f, buffer.Sample(0.5)!.Value.X); // ältester ist jetzt t=2.0
    }

    [Fact]
    public void Clear_EmptiesBuffer()
    {
        var buffer = new SnapshotBuffer();
        buffer.Add(Snap(1.0, 1f));

        buffer.Clear();

        Assert.Equal(0, buffer.Count);
        Assert.Null(buffer.Sample(2.0));
    }

    [Theory]
    [InlineData(-0.1, 32)] // negative Verzögerung
    [InlineData(0.1, 1)]   // Kapazität < 2
    public void Constructor_InvalidArguments_Throw(double delay, int capacity)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new SnapshotBuffer(delay, capacity));
    }
}
