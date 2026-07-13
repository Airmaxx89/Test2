using System;
using System.Numerics;
using Aethermoor.Gameplay.Enemies;
using Xunit;

namespace Aethermoor.Tests;

public sealed class EnemyBrainTests
{
    private static readonly Vector2 Home = new(1000f, 1000f);

    private static EnemyDefinition Definition(
        float aggro = 260f,
        float leash = 600f,
        float attackRange = 70f)
        => new("test.gegner", "Testgegner", 120f, 160f, aggro, leash, attackRange);

    private static EnemyBrain Brain(
        EnemyDefinition? definition = null,
        params Vector2[] patrolOffsets)
        => new(definition ?? Definition(), Home, patrolOffsets);

    [Fact]
    public void WithoutPlayer_AndWithoutRoute_StandsAtHome()
    {
        EnemyBrain brain = Brain();

        EnemyAiDecision decision = brain.Decide(Home, null);

        Assert.Equal(EnemyAiState.Patrol, decision.State);
        Assert.Equal(Vector2.Zero, decision.MoveDirection);
        Assert.False(decision.WantsToAttack);
    }

    [Fact]
    public void Patrol_MovesTowardCurrentWaypoint()
    {
        EnemyBrain brain = Brain(null, new Vector2(100f, 0f));

        EnemyAiDecision decision = brain.Decide(Home, null);

        Assert.Equal(EnemyAiState.Patrol, decision.State);
        Assert.Equal(new Vector2(1f, 0f), decision.MoveDirection);
    }

    [Fact]
    public void Patrol_AdvancesToNextWaypoint_WhenReached()
    {
        EnemyBrain brain = Brain(null, new Vector2(100f, 0f), new Vector2(100f, 100f));

        // Am ersten Wegpunkt angekommen -> Richtung zum zweiten (senkrecht nach unten).
        EnemyAiDecision decision = brain.Decide(Home + new Vector2(100f, 0f), null);

        Assert.Equal(new Vector2(0f, 1f), decision.MoveDirection);
    }

    [Fact]
    public void Patrol_LoopsRoute()
    {
        EnemyBrain brain = Brain(null, new Vector2(100f, 0f), new Vector2(100f, 100f));

        brain.Decide(Home + new Vector2(100f, 0f), null);   // Wegpunkt 1 erreicht -> Ziel 2
        EnemyAiDecision decision = brain.Decide(Home + new Vector2(100f, 100f), null); // 2 erreicht -> Ziel 1

        Assert.Equal(new Vector2(0f, -1f), decision.MoveDirection); // zurück nach oben
    }

    [Fact]
    public void PlayerInsideAggroRadius_TriggersChase_TowardPlayer()
    {
        EnemyBrain brain = Brain();
        Vector2 player = Home + new Vector2(200f, 0f); // 200 < 260

        EnemyAiDecision decision = brain.Decide(Home, player);

        Assert.Equal(EnemyAiState.Chase, decision.State);
        Assert.Equal(new Vector2(1f, 0f), decision.MoveDirection);
    }

    [Fact]
    public void PlayerOutsideAggroRadius_DoesNotTriggerChase()
    {
        EnemyBrain brain = Brain();

        EnemyAiDecision decision = brain.Decide(Home, Home + new Vector2(300f, 0f)); // 300 > 260

        Assert.Equal(EnemyAiState.Patrol, decision.State);
    }

    [Fact]
    public void Aggro_IsSticky_BeyondAggroRadius()
    {
        EnemyBrain brain = Brain();
        brain.Decide(Home, Home + new Vector2(200f, 0f)); // Aggro gezogen

        // Spieler nun außerhalb des Aggro-Radius, aber innerhalb der Leine.
        EnemyAiDecision decision = brain.Decide(
            Home + new Vector2(100f, 0f), Home + new Vector2(500f, 0f));

        Assert.Equal(EnemyAiState.Chase, decision.State);
    }

    [Fact]
    public void WithinAttackRange_AttacksWithoutMoving()
    {
        EnemyBrain brain = Brain();
        Vector2 player = Home + new Vector2(50f, 0f); // 50 <= 70

        EnemyAiDecision decision = brain.Decide(Home, player);

        Assert.Equal(EnemyAiState.Attack, decision.State);
        Assert.Equal(Vector2.Zero, decision.MoveDirection);
        Assert.True(decision.WantsToAttack);
    }

    [Fact]
    public void LeashExceeded_StartsReturn()
    {
        EnemyBrain brain = Brain(Definition(leash: 600f));
        brain.Decide(Home, Home + new Vector2(200f, 0f)); // Aggro

        // Gegner wurde 700 px vom Heimatpunkt weggelockt -> Leine reißt.
        EnemyAiDecision decision = brain.Decide(
            Home + new Vector2(700f, 0f), Home + new Vector2(760f, 0f));

        Assert.Equal(EnemyAiState.Return, decision.State);
        Assert.Equal(new Vector2(-1f, 0f), decision.MoveDirection); // heimwärts
    }

    [Fact]
    public void DuringReturn_IgnoresPlayer()
    {
        EnemyBrain brain = Brain();
        brain.Decide(Home, Home + new Vector2(200f, 0f));                       // Aggro
        brain.Decide(Home + new Vector2(700f, 0f), Home + new Vector2(760f, 0f)); // Leine -> Return

        // Spieler steht direkt daneben — wird während der Heimkehr ignoriert.
        EnemyAiDecision decision = brain.Decide(
            Home + new Vector2(400f, 0f), Home + new Vector2(410f, 0f));

        Assert.Equal(EnemyAiState.Return, decision.State);
        Assert.False(decision.WantsToAttack);
    }

    [Fact]
    public void ReachingHome_ResumesPatrol()
    {
        EnemyBrain brain = Brain();
        brain.Decide(Home, Home + new Vector2(200f, 0f));
        brain.Decide(Home + new Vector2(700f, 0f), Home + new Vector2(760f, 0f)); // Return

        EnemyAiDecision decision = brain.Decide(Home + new Vector2(2f, 0f), null); // angekommen

        Assert.Equal(EnemyAiState.Patrol, decision.State);
    }

    [Fact]
    public void PlayerVanishesDuringChase_StartsReturn()
    {
        EnemyBrain brain = Brain();
        brain.Decide(Home, Home + new Vector2(200f, 0f)); // Aggro

        EnemyAiDecision decision = brain.Decide(Home + new Vector2(100f, 0f), null);

        Assert.Equal(EnemyAiState.Return, decision.State);
    }

    [Fact]
    public void Constructor_NullArguments_Throw()
    {
        Assert.Throws<ArgumentNullException>(() => new EnemyBrain(null!, Home, Array.Empty<Vector2>()));
        Assert.Throws<ArgumentNullException>(() => new EnemyBrain(Definition(), Home, null!));
    }
}
