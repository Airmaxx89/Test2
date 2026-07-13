using System;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Character;
using Aethermoor.Gameplay.Combat;
using Aethermoor.Gameplay.Targeting;
using Godot;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.Gameplay.Enemies;

/// <summary>
/// Godot-Anbindung eines Gegners: besitzt <see cref="EnemyBrain"/> (KI) und
/// <see cref="HealthPool"/> (Leben), setzt KI-Entscheidungen in Bewegung um und stellt
/// Lebensbalken, Zustandsfarbe und Ziel-Markierung dar. Registriert sich in der
/// Godot-Gruppe <see cref="EnemiesGroup"/>, über die das Zielsystem Kandidaten einsammelt.
/// </summary>
/// <remarks>
/// Dünne Schicht: alle Verhaltens- und Lebensregeln liegen in den getesteten, engine-freien
/// Kernklassen. Die Werte kommen als Daten (<see cref="EnemyResource"/>-Pfad).
/// </remarks>
public sealed partial class EnemyController : Node2D
{
    /// <summary>Gruppenname, unter dem alle Gegner auffindbar sind.</summary>
    public const string EnemiesGroup = "enemies";

    private const string LogCategory = "Enemies";
    private const float BodyHalfSize = 22f;

    private static readonly Color PatrolColor = new(0.75f, 0.35f, 0.30f);
    private static readonly Color ChaseColor = new(0.95f, 0.25f, 0.15f);
    private static readonly Color ReturnColor = new(0.75f, 0.60f, 0.25f);
    private static readonly Color DeadColor = new(0.35f, 0.35f, 0.38f);
    private static readonly Color HealthBackColor = new(0f, 0f, 0f, 0.6f);
    private static readonly Color HealthFillColor = new(0.30f, 0.85f, 0.35f);
    private static readonly Color TargetRingColor = new(1f, 1f, 1f, 0.9f);

    /// <summary>Ressourcenpfad der Gegnerdefinition (<c>res://…tres</c>).</summary>
    [Export] public string DefinitionPath { get; set; } = string.Empty;

    /// <summary>Pfad zur Spielfigur (Aggro-/Verfolgungsziel).</summary>
    [Export] public NodePath PlayerPath { get; set; } = new();

    /// <summary>Patrouillen-Wegpunkte relativ zum Spawnpunkt (leer = stehen).</summary>
    [Export] public Vector2[] PatrolOffsets { get; set; } = Array.Empty<Vector2>();

    private GameBootstrap _game = null!;
    private EnemyDefinition _definition = null!;
    private EnemyBrain _brain = null!;
    private HealthPool _health = null!;
    private AttackTicker _attackTicker = null!;
    private Node2D? _player;
    private LocalCharacterController? _playerCharacter;
    private bool _isTargeted;

    /// <summary>Ob der Gegner tot ist (nicht mehr anvisierbar).</summary>
    public bool IsDead => _health.IsDead;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _player = GetNodeOrNull<Node2D>(PlayerPath);

        if (ResourceLoader.Load<EnemyResource>(DefinitionPath) is not EnemyResource resource)
        {
            _game.Logger.Error(LogCategory, $"Gegnerdefinition nicht ladbar: '{DefinitionPath}'.");
            SetPhysicsProcess(false);
            return;
        }

        _definition = resource.ToDefinition();
        _health = new HealthPool(_definition.MaxHealth);
        _attackTicker = new AttackTicker(_definition.AttackIntervalSeconds);
        _playerCharacter = _player as LocalCharacterController;

        var home = new NumericsVector2(GlobalPosition.X, GlobalPosition.Y);
        var offsets = new NumericsVector2[PatrolOffsets.Length];
        for (int i = 0; i < PatrolOffsets.Length; i++)
        {
            offsets[i] = new NumericsVector2(PatrolOffsets[i].X, PatrolOffsets[i].Y);
        }

        _brain = new EnemyBrain(_definition, home, offsets);
        AddToGroup(EnemiesGroup);
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_health.IsDead)
        {
            return;
        }

        NumericsVector2? playerPosition = _player is null
            ? null
            : new NumericsVector2(_player.GlobalPosition.X, _player.GlobalPosition.Y);

        var self = new NumericsVector2(GlobalPosition.X, GlobalPosition.Y);
        EnemyAiDecision decision = _brain.Decide(self, playerPosition);

        GlobalPosition += new Vector2(decision.MoveDirection.X, decision.MoveDirection.Y)
            * _definition.MoveSpeed * (float)delta;

        if (decision.WantsToAttack && _attackTicker.TryAttack(Time.GetTicksMsec() / 1000.0))
        {
            _playerCharacter?.ApplyDamage(_definition.AttackDamage);
        }

        QueueRedraw();
    }

    /// <summary>Liefert die Zielbeschreibung für den <see cref="SmartTargetSelector"/>.</summary>
    public TargetCandidate ToCandidate()
        => new(
            unchecked((long)GetInstanceId()),
            new NumericsVector2(GlobalPosition.X, GlobalPosition.Y),
            IsTargetable: !_health.IsDead);

    /// <summary>
    /// Wendet (prädiktiven) Schaden an und liefert den tatsächlich abgezogenen Betrag;
    /// bei 0 Leben stirbt der Gegner sichtbar.
    /// </summary>
    public float ApplyDamage(float amount)
    {
        float applied = _health.ApplyDamage(amount);
        if (applied <= 0f)
        {
            return 0f;
        }

        if (_health.IsDead)
        {
            RemoveFromGroup(EnemiesGroup);
            _isTargeted = false;
            _game.Logger.Info(LogCategory, $"{_definition.DisplayName} besiegt.");
        }

        QueueRedraw();
        return applied;
    }

    /// <summary>Setzt die sichtbare Ziel-Markierung (vom Zielsystem gesteuert).</summary>
    public void SetTargeted(bool targeted)
    {
        if (_isTargeted == targeted)
        {
            return;
        }

        _isTargeted = targeted;
        QueueRedraw();
    }

    public override void _Draw()
    {
        Color bodyColor = _health.IsDead
            ? DeadColor
            : _brain.State switch
            {
                EnemyAiState.Chase or EnemyAiState.Attack => ChaseColor,
                EnemyAiState.Return => ReturnColor,
                _ => PatrolColor,
            };

        // Körper (Platzhalter bis zu echten Modellen) + optionale Ziel-Markierung.
        DrawRect(
            new Rect2(-BodyHalfSize, -BodyHalfSize, BodyHalfSize * 2f, BodyHalfSize * 2f),
            bodyColor);
        if (_isTargeted)
        {
            DrawArc(Vector2.Zero, BodyHalfSize + 10f, 0f, Mathf.Tau, 40, TargetRingColor, 3f);
        }

        // Lebensbalken über dem Körper.
        if (!_health.IsDead)
        {
            const float barWidth = 52f;
            const float barHeight = 6f;
            var barOrigin = new Vector2(-barWidth / 2f, -BodyHalfSize - 16f);
            DrawRect(new Rect2(barOrigin, new Vector2(barWidth, barHeight)), HealthBackColor);
            DrawRect(
                new Rect2(barOrigin, new Vector2(barWidth * _health.Fraction, barHeight)),
                HealthFillColor);
        }
    }
}
