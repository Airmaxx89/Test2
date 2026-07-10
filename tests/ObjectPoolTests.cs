using System;
using Aethermoor.Core.Pooling;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ObjectPoolTests
{
    private sealed class Tracked : IPoolable
    {
        public int RentCount { get; private set; }
        public int ReturnCount { get; private set; }

        public void OnRent() => RentCount++;
        public void OnReturn() => ReturnCount++;
    }

    [Fact]
    public void Rent_OnEmptyPool_CreatesViaFactory()
    {
        int created = 0;
        var pool = new ObjectPool<object>(() => { created++; return new object(); });

        _ = pool.Rent();

        Assert.Equal(1, created);
        Assert.Equal(1, pool.CountInUse);
        Assert.Equal(0, pool.CountAvailable);
    }

    [Fact]
    public void Return_ThenRent_ReusesInstance_WithoutNewAllocation()
    {
        int created = 0;
        var pool = new ObjectPool<object>(() => { created++; return new object(); });

        object first = pool.Rent();
        pool.Return(first);
        object second = pool.Rent();

        Assert.Same(first, second);
        Assert.Equal(1, created);
    }

    [Fact]
    public void Prewarm_PopulatesAvailableInstances()
    {
        var pool = new ObjectPool<object>(() => new object(), prewarm: 3);
        Assert.Equal(3, pool.CountAvailable);
        Assert.Equal(0, pool.CountInUse);
    }

    [Fact]
    public void Counts_TrackRentAndReturn()
    {
        var pool = new ObjectPool<object>(() => new object());

        object a = pool.Rent();
        object b = pool.Rent();
        Assert.Equal(2, pool.CountInUse);

        pool.Return(a);
        Assert.Equal(1, pool.CountInUse);
        Assert.Equal(1, pool.CountAvailable);

        pool.Return(b);
        Assert.Equal(0, pool.CountInUse);
        Assert.Equal(2, pool.CountAvailable);
    }

    [Fact]
    public void MaxSize_DiscardsReturnsBeyondCapacity()
    {
        var pool = new ObjectPool<object>(() => new object(), maxSize: 1);

        object a = pool.Rent();
        object b = pool.Rent();
        pool.Return(a);
        pool.Return(b); // über der Obergrenze -> wird verworfen

        Assert.Equal(1, pool.CountAvailable);
        Assert.Equal(0, pool.CountInUse);
    }

    [Fact]
    public void IPoolable_Hooks_AreInvoked()
    {
        var pool = new ObjectPool<Tracked>(() => new Tracked());

        Tracked item = pool.Rent();
        Assert.Equal(1, item.RentCount);
        Assert.Equal(0, item.ReturnCount);

        pool.Return(item);
        Assert.Equal(1, item.ReturnCount);
    }

    [Fact]
    public void OptionalCallbacks_AreInvoked()
    {
        int rented = 0;
        int returned = 0;
        var pool = new ObjectPool<object>(
            factory: () => new object(),
            onRent: _ => rented++,
            onReturn: _ => returned++);

        object item = pool.Rent();
        pool.Return(item);

        Assert.Equal(1, rented);
        Assert.Equal(1, returned);
    }

    [Fact]
    public void Return_MoreThanRented_Throws()
    {
        var pool = new ObjectPool<object>(() => new object());
        Assert.Throws<InvalidOperationException>(() => pool.Return(new object()));
    }

    [Fact]
    public void Return_Null_Throws()
    {
        var pool = new ObjectPool<object>(() => new object());
        _ = pool.Rent();
        Assert.Throws<ArgumentNullException>(() => pool.Return(null!));
    }

    [Fact]
    public void Constructor_NullFactory_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new ObjectPool<object>(null!));
    }

    [Theory]
    [InlineData(-1, 10)]
    [InlineData(0, 0)]
    public void Constructor_InvalidArguments_Throw(int prewarm, int maxSize)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => new ObjectPool<object>(() => new object(), prewarm: prewarm, maxSize: maxSize));
    }
}
