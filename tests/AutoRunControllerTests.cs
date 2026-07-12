using System;
using System.Numerics;
using Aethermoor.Gameplay.Input;
using Xunit;

namespace Aethermoor.Tests;

public sealed class AutoRunControllerTests
{
    private static readonly Vector2 Right = new(1f, 0f);
    private static readonly Vector2 Left = new(-1f, 0f);
    private static readonly Vector2 Up = new(0f, -1f);

    [Fact]
    public void Inactive_PassesLiveInputThrough()
    {
        var controller = new AutoRunController();

        Vector2 result = controller.Resolve(new Vector2(0.5f, 0f));

        Assert.False(controller.IsActive);
        Assert.Equal(new Vector2(0.5f, 0f), result);
    }

    [Fact]
    public void Toggle_WithLiveInput_ActivatesAndLatchesDirection()
    {
        var controller = new AutoRunController();

        controller.Toggle(Right, Vector2.Zero);

        Assert.True(controller.IsActive);
        // Volle Laufgeschwindigkeit entlang der eingerasteten Richtung.
        Assert.Equal(Right, controller.Resolve(Vector2.Zero));
    }

    [Fact]
    public void Toggle_WithoutInput_UsesFallbackFacing()
    {
        var controller = new AutoRunController();

        controller.Toggle(Vector2.Zero, Up);

        Assert.True(controller.IsActive);
        Assert.Equal(Up, controller.Resolve(Vector2.Zero));
    }

    [Fact]
    public void Toggle_WithoutInputAndZeroFacing_StaysInactive()
    {
        var controller = new AutoRunController();

        controller.Toggle(Vector2.Zero, Vector2.Zero);

        Assert.False(controller.IsActive);
    }

    [Fact]
    public void Toggle_WhileActive_Deactivates()
    {
        var controller = new AutoRunController();
        controller.Toggle(Right, Vector2.Zero);

        controller.Toggle(Right, Vector2.Zero);

        Assert.False(controller.IsActive);
    }

    [Fact]
    public void Active_BelowThresholdInput_KeepsLatchedDirection()
    {
        var controller = new AutoRunController(inputThreshold: 0.2f);
        controller.Toggle(Right, Vector2.Zero);

        Vector2 result = controller.Resolve(new Vector2(0.1f, 0f)); // unter Schwelle

        Assert.True(controller.IsActive);
        Assert.Equal(Right, result);
    }

    [Fact]
    public void Active_SidewaysInput_SteersWithoutCancelling()
    {
        var controller = new AutoRunController();
        controller.Toggle(Right, Vector2.Zero);

        Vector2 result = controller.Resolve(Up); // 90° zur Laufrichtung, dot = 0 >= -0.5

        Assert.True(controller.IsActive);
        Assert.Equal(Up, result); // Laufrichtung wurde nachgeführt
    }

    [Fact]
    public void Active_OppositeInput_CancelsAndReturnsLiveInput()
    {
        var controller = new AutoRunController();
        controller.Toggle(Right, Vector2.Zero);

        Vector2 result = controller.Resolve(Left); // dot = -1 < -0.5 -> Abbruch

        Assert.False(controller.IsActive);
        Assert.Equal(Left, result);
    }

    [Fact]
    public void Cancel_Deactivates()
    {
        var controller = new AutoRunController();
        controller.Toggle(Right, Vector2.Zero);

        controller.Cancel();

        Assert.False(controller.IsActive);
        Assert.Equal(new Vector2(0.3f, 0f), controller.Resolve(new Vector2(0.3f, 0f)));
    }

    [Theory]
    [InlineData(-0.1f, 0f)]
    [InlineData(1.1f, 0f)]
    [InlineData(0.2f, -1.5f)]
    [InlineData(0.2f, 1.5f)]
    public void Constructor_InvalidArguments_Throw(float inputThreshold, float cancelDot)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => new AutoRunController(inputThreshold, cancelDot));
    }
}
