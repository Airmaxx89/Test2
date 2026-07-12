using System;
using System.Collections.Generic;
using System.Numerics;
using Aethermoor.Gameplay.Targeting;
using Xunit;

namespace Aethermoor.Tests;

public sealed class SmartTargetSelectorTests
{
    private static readonly Vector2 Origin = Vector2.Zero;
    private static readonly Vector2 FacingRight = new(1f, 0f);

    private static TargetCandidate Target(long id, float x, float y, bool targetable = true)
        => new(id, new Vector2(x, y), targetable);

    [Fact]
    public void NoCandidates_ReturnsNull()
    {
        var selector = new SmartTargetSelector(maxRange: 100f, coneHalfAngleDegrees: 60f);

        long? result = selector.SelectTarget(Origin, FacingRight, Array.Empty<TargetCandidate>());

        Assert.Null(result);
    }

    [Fact]
    public void SingleTargetInRangeAndCone_IsSelected()
    {
        var selector = new SmartTargetSelector(100f, 60f);
        var candidates = new[] { Target(7, 50f, 0f) };

        Assert.Equal(7, selector.SelectTarget(Origin, FacingRight, candidates));
    }

    [Fact]
    public void TargetBeyondRange_IsExcluded()
    {
        var selector = new SmartTargetSelector(100f, 60f);
        var candidates = new[] { Target(1, 150f, 0f) };

        Assert.Null(selector.SelectTarget(Origin, FacingRight, candidates));
    }

    [Fact]
    public void TargetBehindPlayer_IsExcludedByCone()
    {
        var selector = new SmartTargetSelector(100f, 60f);
        var candidates = new[] { Target(1, -50f, 0f) }; // hinter dem nach rechts blickenden Spieler

        Assert.Null(selector.SelectTarget(Origin, FacingRight, candidates));
    }

    [Fact]
    public void NonTargetableCandidate_IsIgnored()
    {
        var selector = new SmartTargetSelector(100f, 60f);
        var candidates = new[] { Target(1, 50f, 0f, targetable: false) };

        Assert.Null(selector.SelectTarget(Origin, FacingRight, candidates));
    }

    [Fact]
    public void WithDistanceWeightOne_ClosestInConeWins()
    {
        var selector = new SmartTargetSelector(100f, 80f, distanceWeight: 1f);
        var candidates = new[]
        {
            Target(1, 80f, 0f),  // weiter weg, perfekt zentriert
            Target(2, 30f, 10f), // näher, leicht seitlich
        };

        Assert.Equal(2, selector.SelectTarget(Origin, FacingRight, candidates));
    }

    [Fact]
    public void WithDistanceWeightZero_MostAlignedWins()
    {
        var selector = new SmartTargetSelector(100f, 80f, distanceWeight: 0f);
        var candidates = new[]
        {
            Target(1, 80f, 0f),  // weiter weg, aber direkt voraus
            Target(2, 30f, 25f), // näher, aber deutlich seitlich
        };

        Assert.Equal(1, selector.SelectTarget(Origin, FacingRight, candidates));
    }

    [Fact]
    public void ZeroFacing_SelectsByProximity_IgnoringCone()
    {
        var selector = new SmartTargetSelector(100f, 30f, distanceWeight: 1f);
        var candidates = new[]
        {
            Target(1, -20f, 0f), // hinter dem Spieler, aber am nächsten
            Target(2, 60f, 0f),
        };

        // Ohne Blickrichtung entfällt der Kegelfilter -> das nächste Ziel gewinnt.
        Assert.Equal(1, selector.SelectTarget(Origin, Vector2.Zero, candidates));
    }

    [Fact]
    public void EqualScore_KeepsFirstEvaluatedCandidate()
    {
        var selector = new SmartTargetSelector(100f, 90f, distanceWeight: 1f);
        var candidates = new[]
        {
            Target(10, 40f, 0f),
            Target(20, 0f, 40f), // gleiche Entfernung, gleicher Score
        };

        Assert.Equal(10, selector.SelectTarget(Origin, Vector2.Zero, candidates));
    }

    [Fact]
    public void SelectTarget_NullCandidates_Throws()
    {
        var selector = new SmartTargetSelector(100f, 60f);

        Assert.Throws<ArgumentNullException>(
            () => selector.SelectTarget(Origin, FacingRight, null!));
    }

    [Theory]
    [InlineData(0f, 60f, 0.5f)]
    [InlineData(-10f, 60f, 0.5f)]
    [InlineData(100f, 0f, 0.5f)]
    [InlineData(100f, 200f, 0.5f)]
    [InlineData(100f, 60f, -0.1f)]
    [InlineData(100f, 60f, 1.1f)]
    public void Constructor_InvalidArguments_Throw(float maxRange, float coneHalfAngle, float weight)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => new SmartTargetSelector(maxRange, coneHalfAngle, weight));
    }
}
