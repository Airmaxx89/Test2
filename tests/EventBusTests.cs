using System;
using Aethermoor.Core.Diagnostics;
using Aethermoor.Core.Events;
using Aethermoor.Tests.TestDoubles;
using Xunit;

namespace Aethermoor.Tests;

public sealed class EventBusTests
{
    private readonly record struct SampleEvent(int Payload) : IGameEvent;
    private readonly record struct OtherEvent(string Text) : IGameEvent;

    [Fact]
    public void Publish_InvokesSubscribedHandler_WithPayload()
    {
        var bus = new EventBus(new RecordingLogger());
        int received = 0;
        bus.Subscribe<SampleEvent>(e => received = e.Payload);

        bus.Publish(new SampleEvent(99));

        Assert.Equal(99, received);
    }

    [Fact]
    public void Publish_InvokesAllHandlers()
    {
        var bus = new EventBus(new RecordingLogger());
        int calls = 0;
        bus.Subscribe<SampleEvent>(_ => calls++);
        bus.Subscribe<SampleEvent>(_ => calls++);

        bus.Publish(new SampleEvent(1));

        Assert.Equal(2, calls);
    }

    [Fact]
    public void Publish_DoesNotInvokeHandlersOfOtherEventTypes()
    {
        var bus = new EventBus(new RecordingLogger());
        bool otherCalled = false;
        bus.Subscribe<OtherEvent>(_ => otherCalled = true);

        bus.Publish(new SampleEvent(1));

        Assert.False(otherCalled);
    }

    [Fact]
    public void Unsubscribe_StopsFurtherDelivery()
    {
        var bus = new EventBus(new RecordingLogger());
        int calls = 0;
        void Handler(SampleEvent _) => calls++;

        bus.Subscribe<SampleEvent>(Handler);
        bus.Publish(new SampleEvent(1));
        bus.Unsubscribe<SampleEvent>(Handler);
        bus.Publish(new SampleEvent(2));

        Assert.Equal(1, calls);
    }

    [Fact]
    public void Subscribe_SameHandlerTwice_IsIdempotent()
    {
        var bus = new EventBus(new RecordingLogger());
        int calls = 0;
        void Handler(SampleEvent _) => calls++;

        bus.Subscribe<SampleEvent>(Handler);
        bus.Subscribe<SampleEvent>(Handler);
        bus.Publish(new SampleEvent(1));

        Assert.Equal(1, calls);
    }

    [Fact]
    public void Publish_WithNoSubscribers_DoesNotThrow()
    {
        var bus = new EventBus(new RecordingLogger());
        bus.Publish(new SampleEvent(1)); // darf einfach nichts tun
    }

    [Fact]
    public void Publish_HandlerException_IsLogged_AndOtherHandlersStillRun()
    {
        var logger = new RecordingLogger();
        var bus = new EventBus(logger);
        bool secondRan = false;

        bus.Subscribe<SampleEvent>(_ => throw new InvalidOperationException("boom"));
        bus.Subscribe<SampleEvent>(_ => secondRan = true);

        bus.Publish(new SampleEvent(1));

        Assert.True(secondRan);
        Assert.Contains(logger.Entries, e => e.Level == LogLevel.Error);
    }

    [Fact]
    public void Publish_HandlerThatUnsubscribes_DoesNotDisruptDelivery()
    {
        var bus = new EventBus(new RecordingLogger());
        int calls = 0;
        void SelfRemoving(SampleEvent _)
        {
            calls++;
            bus.Unsubscribe<SampleEvent>(SelfRemoving);
        }

        bus.Subscribe<SampleEvent>(SelfRemoving);
        bus.Subscribe<SampleEvent>(_ => calls++);

        bus.Publish(new SampleEvent(1)); // Snapshot schützt die laufende Zustellung
        bus.Publish(new SampleEvent(2)); // SelfRemoving ist nun abgemeldet

        Assert.Equal(3, calls);
    }

    [Fact]
    public void Clear_RemovesAllSubscriptions()
    {
        var bus = new EventBus(new RecordingLogger());
        int calls = 0;
        bus.Subscribe<SampleEvent>(_ => calls++);

        bus.Clear();
        bus.Publish(new SampleEvent(1));

        Assert.Equal(0, calls);
    }

    [Fact]
    public void Constructor_NullLogger_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new EventBus(null!));
    }
}
