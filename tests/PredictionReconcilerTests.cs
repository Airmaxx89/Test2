using System;
using System.Numerics;
using Aethermoor.Networking.Replication;
using Xunit;

namespace Aethermoor.Tests;

public sealed class PredictionReconcilerTests
{
    private const float Speed = 100f;

    // Gemeinsame Bewegungsformel für Client-Prediction und "Server" in diesen Tests.
    private static Vector2 Step(Vector2 position, Vector2 direction, float dt)
        => position + (direction * Speed * dt);

    private static readonly Vector2 Right = new(1f, 0f);

    [Fact]
    public void ApplyLocalInput_MovesPredictionImmediately()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);

        reconciler.ApplyLocalInput(Right, 0.1f); // 100 · 0,1 = 10

        Assert.Equal(10f, reconciler.PredictedPosition.X, precision: 4);
        Assert.Equal(1, reconciler.PendingCount);
    }

    [Fact]
    public void Sequences_IncreaseMonotonically()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);

        MovementInput first = reconciler.ApplyLocalInput(Right, 0.1f);
        MovementInput second = reconciler.ApplyLocalInput(Right, 0.1f);

        Assert.True(second.Sequence > first.Sequence);
    }

    [Fact]
    public void Reconcile_WithMatchingServerState_KeepsPrediction()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);

        MovementInput a = reconciler.ApplyLocalInput(Right, 0.1f); // -> 10
        reconciler.ApplyLocalInput(Right, 0.1f);                   // -> 20

        // Server bestätigt Eingabe a exakt dort, wo der Client sie vorhergesagt hat.
        Vector2 corrected = reconciler.Reconcile(a.Sequence, new Vector2(10f, 0f));

        Assert.Equal(20f, corrected.X, precision: 4); // Replay der offenen Eingabe
        Assert.Equal(1, reconciler.PendingCount);
    }

    [Fact]
    public void Reconcile_WithServerCorrection_ReplaysPendingInputsFromServerPosition()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);

        MovementInput a = reconciler.ApplyLocalInput(Right, 0.1f); // Client: 10
        reconciler.ApplyLocalInput(Right, 0.1f);                   // Client: 20

        // Server hat Eingabe a anders aufgelöst (z. B. Kollision): Position 5 statt 10.
        Vector2 corrected = reconciler.Reconcile(a.Sequence, new Vector2(5f, 0f));

        // 5 + Replay der zweiten Eingabe (10) = 15.
        Assert.Equal(15f, corrected.X, precision: 4);
        Assert.Equal(15f, reconciler.PredictedPosition.X, precision: 4);
    }

    [Fact]
    public void Reconcile_AcknowledgingEverything_SnapsToServerPosition()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);

        MovementInput a = reconciler.ApplyLocalInput(Right, 0.1f);
        MovementInput b = reconciler.ApplyLocalInput(Right, 0.1f);
        Assert.True(b.Sequence > a.Sequence);

        Vector2 corrected = reconciler.Reconcile(b.Sequence, new Vector2(7f, 0f));

        Assert.Equal(7f, corrected.X, precision: 4);
        Assert.Equal(0, reconciler.PendingCount);
    }

    [Fact]
    public void Reconcile_WithStaleAck_DoesNotDropNewerInputs()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);

        reconciler.ApplyLocalInput(Right, 0.1f);
        reconciler.ApplyLocalInput(Right, 0.1f);

        // Ack 0 = noch nichts bestätigt: alle Eingaben werden ab Serverposition neu angewendet.
        Vector2 corrected = reconciler.Reconcile(0, Vector2.Zero);

        Assert.Equal(20f, corrected.X, precision: 4);
        Assert.Equal(2, reconciler.PendingCount);
    }

    [Fact]
    public void Reset_ClearsPendingAndSetsPosition()
    {
        var reconciler = new PredictionReconciler(Step);
        reconciler.Reset(Vector2.Zero);
        reconciler.ApplyLocalInput(Right, 0.1f);

        reconciler.Reset(new Vector2(500f, 500f));

        Assert.Equal(0, reconciler.PendingCount);
        Assert.Equal(500f, reconciler.PredictedPosition.X);
    }

    [Fact]
    public void PendingBuffer_IsBounded()
    {
        var reconciler = new PredictionReconciler(Step, maxPendingInputs: 3);
        reconciler.Reset(Vector2.Zero);

        for (int i = 0; i < 10; i++)
        {
            reconciler.ApplyLocalInput(Right, 0.1f);
        }

        Assert.Equal(3, reconciler.PendingCount);
    }

    [Fact]
    public void Constructor_NullStep_Throws()
    {
        Assert.Throws<ArgumentNullException>(() => new PredictionReconciler(null!));
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    public void Constructor_NonPositiveBuffer_Throws(int maxPending)
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => new PredictionReconciler(Step, maxPending));
    }
}
