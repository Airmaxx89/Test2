using System;
using Aethermoor.Core.Services;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ServiceLocatorTests
{
    private interface ISampleService : IService
    {
        int Value { get; }
    }

    private sealed class SampleService : ISampleService
    {
        public int Value { get; }
        public bool Initialized { get; private set; }
        public bool WasShutDown { get; private set; }

        public SampleService(int value) => Value = value;

        public void Initialize() => Initialized = true;
        public void Shutdown() => WasShutDown = true;
    }

    private sealed class OtherService : IService
    {
        public void Initialize() { }
        public void Shutdown() { }
    }

    [Fact]
    public void Get_ReturnsRegisteredInstance()
    {
        var locator = new ServiceLocator();
        var service = new SampleService(42);

        locator.Register<ISampleService>(service);

        Assert.Same(service, locator.Get<ISampleService>());
        Assert.Equal(42, locator.Get<ISampleService>().Value);
    }

    [Fact]
    public void Register_Twice_SameType_Throws()
    {
        var locator = new ServiceLocator();
        locator.Register<ISampleService>(new SampleService(1));

        Assert.Throws<InvalidOperationException>(
            () => locator.Register<ISampleService>(new SampleService(2)));
    }

    [Fact]
    public void Register_Null_Throws()
    {
        var locator = new ServiceLocator();
        Assert.Throws<ArgumentNullException>(() => locator.Register<ISampleService>(null!));
    }

    [Fact]
    public void Get_Unregistered_Throws()
    {
        var locator = new ServiceLocator();
        Assert.Throws<InvalidOperationException>(() => locator.Get<ISampleService>());
    }

    [Fact]
    public void TryGet_ReflectsRegistrationState()
    {
        var locator = new ServiceLocator();
        Assert.False(locator.TryGet<ISampleService>(out ISampleService? missing));
        Assert.Null(missing);

        var service = new SampleService(7);
        locator.Register<ISampleService>(service);

        Assert.True(locator.TryGet<ISampleService>(out ISampleService? found));
        Assert.Same(service, found);
    }

    [Fact]
    public void All_EnumeratesEveryRegisteredService()
    {
        var locator = new ServiceLocator();
        locator.Register<ISampleService>(new SampleService(1));
        locator.Register<OtherService>(new OtherService());

        Assert.Equal(2, locator.All.Count);
    }

    [Fact]
    public void Clear_RemovesAllRegistrations()
    {
        var locator = new ServiceLocator();
        locator.Register<ISampleService>(new SampleService(1));

        locator.Clear();

        Assert.False(locator.TryGet<ISampleService>(out _));
        Assert.Empty(locator.All);
    }
}
