using System;
using System.Numerics;
using Aethermoor.Gameplay.Input;
using Xunit;

namespace Aethermoor.Tests;

public sealed class VirtualJoystickProcessorTests
{
    private const float Radius = 100f;
    private const float DeadZone = 0.2f; // -> 20 px Totzone
    private static readonly Vector2 Center = new(500f, 500f);

    private static VirtualJoystickProcessor Create() => new(Radius, DeadZone);

    [Fact]
    public void CenteredTouch_IsInactive()
    {
        JoystickOutput output = Create().Compute(Center, Center);

        Assert.Equal(Vector2.Zero, output.Direction);
        Assert.Equal(0f, output.Magnitude);
        Assert.Equal(Vector2.Zero, output.HandleOffset);
    }

    [Fact]
    public void WithinDeadZone_HasNoDirectionButVisibleHandle()
    {
        // 10 px nach rechts: innerhalb der 20-px-Totzone.
        JoystickOutput output = Create().Compute(Center, Center + new Vector2(10f, 0f));

        Assert.Equal(Vector2.Zero, output.Direction);
        Assert.Equal(0f, output.Magnitude);
        Assert.Equal(new Vector2(10f, 0f), output.HandleOffset); // Griff folgt sichtbar
    }

    [Fact]
    public void AtRadius_YieldsUnitDirectionAndFullMagnitude()
    {
        JoystickOutput output = Create().Compute(Center, Center + new Vector2(Radius, 0f));

        Assert.Equal(new Vector2(1f, 0f), output.Direction);
        Assert.Equal(1f, output.Magnitude, precision: 5);
        Assert.Equal(new Vector2(Radius, 0f), output.HandleOffset);
    }

    [Fact]
    public void BeyondRadius_ClampsHandleAndMagnitude()
    {
        JoystickOutput output = Create().Compute(Center, Center + new Vector2(500f, 0f));

        Assert.Equal(new Vector2(1f, 0f), output.Direction);
        Assert.Equal(1f, output.Magnitude, precision: 5);
        Assert.Equal(Radius, output.HandleOffset.Length(), precision: 3); // auf Radius geklemmt
    }

    [Fact]
    public void HalfwayBetweenDeadZoneAndRadius_YieldsHalfMagnitude()
    {
        // 60 px: (60 - 20) / (100 - 20) = 0.5
        JoystickOutput output = Create().Compute(Center, Center + new Vector2(60f, 0f));

        Assert.Equal(0.5f, output.Magnitude, precision: 5);
    }

    [Fact]
    public void Direction_IsAlwaysNormalized_ForDiagonalInput()
    {
        JoystickOutput output = Create().Compute(Center, Center + new Vector2(60f, 60f));

        Assert.Equal(1f, output.Direction.Length(), precision: 4);
        float component = 1f / MathF.Sqrt(2f);
        Assert.Equal(component, output.Direction.X, precision: 4);
        Assert.Equal(component, output.Direction.Y, precision: 4);
    }

    [Fact]
    public void NegativeDirection_IsHandled()
    {
        JoystickOutput output = Create().Compute(Center, Center + new Vector2(0f, -Radius));

        Assert.Equal(new Vector2(0f, -1f), output.Direction);
        Assert.Equal(1f, output.Magnitude, precision: 5);
    }

    [Theory]
    [InlineData(0f)]
    [InlineData(-5f)]
    public void Constructor_NonPositiveRadius_Throws(float radius)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new VirtualJoystickProcessor(radius, DeadZone));
    }

    [Theory]
    [InlineData(-0.1f)]
    [InlineData(1f)]
    [InlineData(1.5f)]
    public void Constructor_DeadZoneOutsideRange_Throws(float deadZone)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new VirtualJoystickProcessor(Radius, deadZone));
    }

    [Fact]
    public void ZeroDeadZone_ProducesMagnitudeProportionalToDistance()
    {
        var processor = new VirtualJoystickProcessor(Radius, 0f);

        JoystickOutput output = processor.Compute(Center, Center + new Vector2(25f, 0f));

        Assert.Equal(0.25f, output.Magnitude, precision: 5);
    }
}
