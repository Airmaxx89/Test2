using System;
using System.Collections.Generic;
using Aethermoor.Networking.Connection;
using Xunit;

namespace Aethermoor.Tests;

public sealed class ConnectionStateMachineTests
{
    [Fact]
    public void New_StartsDisconnected()
    {
        Assert.Equal(ConnectionState.Disconnected, new ConnectionStateMachine().Current);
    }

    [Fact]
    public void ValidTransition_UpdatesStateAndRaisesEvent()
    {
        var machine = new ConnectionStateMachine();
        ConnectionStateChange? observed = null;
        machine.Changed += change => observed = change;

        machine.TransitionTo(ConnectionState.Connecting);

        Assert.Equal(ConnectionState.Connecting, machine.Current);
        Assert.NotNull(observed);
        Assert.Equal(ConnectionState.Disconnected, observed!.Value.Previous);
        Assert.Equal(ConnectionState.Connecting, observed.Value.Current);
    }

    [Fact]
    public void FullHappyPath_Succeeds()
    {
        var machine = new ConnectionStateMachine();

        machine.TransitionTo(ConnectionState.Connecting);
        machine.TransitionTo(ConnectionState.Connected);
        machine.TransitionTo(ConnectionState.Reconnecting);
        machine.TransitionTo(ConnectionState.Connected);
        machine.TransitionTo(ConnectionState.Disconnected);

        Assert.Equal(ConnectionState.Disconnected, machine.Current);
    }

    [Fact]
    public void FailedCanRetryViaConnecting()
    {
        var machine = new ConnectionStateMachine();
        machine.TransitionTo(ConnectionState.Connecting);
        machine.TransitionTo(ConnectionState.Failed);

        Assert.True(machine.CanTransitionTo(ConnectionState.Connecting));
        machine.TransitionTo(ConnectionState.Connecting);
        Assert.Equal(ConnectionState.Connecting, machine.Current);
    }

    [Fact]
    public void InvalidTransition_Throws_AndKeepsState()
    {
        var machine = new ConnectionStateMachine();

        Assert.Throws<InvalidOperationException>(
            () => machine.TransitionTo(ConnectionState.Connected)); // Disconnected -> Connected verboten
        Assert.Equal(ConnectionState.Disconnected, machine.Current);
    }

    [Fact]
    public void SameStateTransition_IsInvalid()
    {
        var machine = new ConnectionStateMachine();
        Assert.False(machine.CanTransitionTo(ConnectionState.Disconnected));
    }

    [Fact]
    public void TryTransitionTo_ReturnsFalse_OnInvalid_WithoutEvent()
    {
        var machine = new ConnectionStateMachine();
        bool eventRaised = false;
        machine.Changed += _ => eventRaised = true;

        bool result = machine.TryTransitionTo(ConnectionState.Connected);

        Assert.False(result);
        Assert.False(eventRaised);
        Assert.Equal(ConnectionState.Disconnected, machine.Current);
    }

    [Fact]
    public void TryTransitionTo_ReturnsTrue_OnValid()
    {
        var machine = new ConnectionStateMachine();
        Assert.True(machine.TryTransitionTo(ConnectionState.Connecting));
        Assert.Equal(ConnectionState.Connecting, machine.Current);
    }

    [Theory]
    [MemberData(nameof(InvalidTransitions))]
    public void RejectedTransitions_AreNotAllowed(ConnectionState from, ConnectionState to)
    {
        var machine = new ConnectionStateMachine();
        Drive(machine, from);

        Assert.False(machine.CanTransitionTo(to));
    }

    public static IEnumerable<object[]> InvalidTransitions() => new[]
    {
        new object[] { ConnectionState.Disconnected, ConnectionState.Connected },
        new object[] { ConnectionState.Disconnected, ConnectionState.Reconnecting },
        new object[] { ConnectionState.Connecting, ConnectionState.Reconnecting },
        new object[] { ConnectionState.Connected, ConnectionState.Connecting },
        new object[] { ConnectionState.Connected, ConnectionState.Failed },
    };

    // Bringt die Maschine über gültige Übergänge in den gewünschten Ausgangszustand.
    private static void Drive(ConnectionStateMachine machine, ConnectionState target)
    {
        switch (target)
        {
            case ConnectionState.Disconnected:
                break;
            case ConnectionState.Connecting:
                machine.TransitionTo(ConnectionState.Connecting);
                break;
            case ConnectionState.Connected:
                machine.TransitionTo(ConnectionState.Connecting);
                machine.TransitionTo(ConnectionState.Connected);
                break;
            case ConnectionState.Reconnecting:
                machine.TransitionTo(ConnectionState.Connecting);
                machine.TransitionTo(ConnectionState.Connected);
                machine.TransitionTo(ConnectionState.Reconnecting);
                break;
            case ConnectionState.Failed:
                machine.TransitionTo(ConnectionState.Connecting);
                machine.TransitionTo(ConnectionState.Failed);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(target), target, null);
        }
    }
}
