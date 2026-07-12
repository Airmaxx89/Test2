using System;
using System.Numerics;
using Aethermoor.World.Camera;
using Xunit;

namespace Aethermoor.Tests;

public sealed class CameraFollowSolverTests
{
    private static readonly Vector2 Origin = Vector2.Zero;
    private static readonly Vector2 Target = new(100f, 0f);

    [Fact]
    public void ZeroSmoothing_SnapsToTarget()
    {
        var solver = new CameraFollowSolver(0f);

        Vector2 result = solver.Step(Origin, Target, 0.016f);

        Assert.Equal(Target, result);
    }

    [Fact]
    public void ZeroDelta_ReturnsCurrentUnchanged()
    {
        var solver = new CameraFollowSolver(8f);

        Vector2 result = solver.Step(Origin, Target, 0f);

        Assert.Equal(Origin, result);
    }

    [Fact]
    public void Step_MovesTowardTarget_ButNotPast()
    {
        var solver = new CameraFollowSolver(8f);

        Vector2 result = solver.Step(Origin, Target, 0.016f);

        Assert.True(result.X > Origin.X, "Kamera bewegt sich zum Ziel.");
        Assert.True(result.X < Target.X, "Kamera überschießt das Ziel nicht.");
    }

    [Fact]
    public void AlreadyAtTarget_StaysAtTarget()
    {
        var solver = new CameraFollowSolver(8f);

        Vector2 result = solver.Step(Target, Target, 0.016f);

        Assert.Equal(Target.X, result.X, precision: 4);
        Assert.Equal(Target.Y, result.Y, precision: 4);
    }

    [Fact]
    public void LargeDelta_ApproachesTargetClosely()
    {
        var solver = new CameraFollowSolver(8f);

        // Über eine ganze Sekunde bei Rate 8 sind ~99,97 % zurückgelegt.
        Vector2 result = solver.Step(Origin, Target, 1f);

        Assert.True(result.X > 99f, $"Erwartet nahe 100, war {result.X}.");
    }

    [Fact]
    public void Smoothing_IsFrameRateIndependent_OverEqualTotalTime()
    {
        var solver = new CameraFollowSolver(8f);

        // Ein Schritt über 0,1 s ...
        Vector2 single = solver.Step(Origin, Target, 0.1f);

        // ... gegen zehn Schritte über je 0,01 s (gleiche Gesamtzeit).
        Vector2 current = Origin;
        for (int i = 0; i < 10; i++)
        {
            current = solver.Step(current, Target, 0.01f);
        }

        // Exponentielle Glättung ist zeitkonsistent: beide landen praktisch gleich.
        Assert.Equal(single.X, current.X, precision: 2);
    }

    [Fact]
    public void Constructor_NegativeSmoothing_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new CameraFollowSolver(-1f));
    }
}
