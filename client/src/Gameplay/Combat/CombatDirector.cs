using System.Collections.Generic;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Abilities;
using Aethermoor.Gameplay.Character;
using Aethermoor.Gameplay.Enemies;
using Aethermoor.Gameplay.Targeting;
using Godot;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.Gameplay.Combat;

/// <summary>
/// Verdrahtet Zielwahl und Wirkung: sammelt pro Physik-Frame alle Gegner (Godot-Gruppe),
/// wählt über den getesteten <see cref="SmartTargetSelector"/> das naheliegendste Ziel
/// (Reichweite + Blickkegel, GAME_DESIGN §7/§13), markiert es sichtbar und liefert der
/// Zauberleiste die Zieldistanz (<see cref="ITargetDistanceProvider"/>). Erfolgreiche
/// Schadens-Fähigkeiten (per EventBus) werden auf das aktuelle Ziel angewendet.
/// </summary>
/// <remarks>
/// Clientlokale Vertikale: Die verbindliche Kampfauflösung wandert mit dem Server-Milestone
/// in den Match-Handler (ADR-0002); dieser Director bleibt dann für Zielwahl und Vorhersage.
/// </remarks>
public sealed partial class CombatDirector : Node, ITargetDistanceProvider
{
    private const string LogCategory = "Combat";

    /// <summary>Pfad zur Spielfigur (<see cref="LocalCharacterController"/>).</summary>
    [Export] public NodePath PlayerPath { get; set; } = new();

    /// <summary>Maximale Zielerfassungs-Reichweite in px.</summary>
    [Export(PropertyHint.Range, "100,2000,10")] public float MaxTargetRange { get; set; } = 600f;

    /// <summary>Halber Öffnungswinkel des Blickkegels in Grad.</summary>
    [Export(PropertyHint.Range, "10,180,5")] public float ConeHalfAngleDegrees { get; set; } = 100f;

    private readonly Dictionary<long, EnemyController> _candidatesById = new();
    private readonly List<TargetCandidate> _candidates = new();

    private GameBootstrap _game = null!;
    private SmartTargetSelector _selector = null!;
    private LocalCharacterController? _player;
    private EnemyController? _currentTarget;

    /// <inheritdoc />
    public float DistanceToTarget { get; private set; } = float.PositiveInfinity;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _player = GetNodeOrNull<LocalCharacterController>(PlayerPath);
        _selector = new SmartTargetSelector(MaxTargetRange, ConeHalfAngleDegrees);

        _game.Events.Subscribe<AbilityCastPredictedEvent>(OnAbilityCast);
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<AbilityCastPredictedEvent>(OnAbilityCast);
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_player is null)
        {
            return;
        }

        CollectCandidates();

        var origin = new NumericsVector2(_player.GlobalPosition.X, _player.GlobalPosition.Y);
        long? selectedId = _selector.SelectTarget(origin, _player.Facing, _candidates);

        EnemyController? selected = selectedId is long id
            ? _candidatesById.GetValueOrDefault(id)
            : null;
        UpdateTargetMarker(selected);

        DistanceToTarget = _currentTarget is null
            ? float.PositiveInfinity
            : _player.GlobalPosition.DistanceTo(_currentTarget.GlobalPosition);
    }

    private void CollectCandidates()
    {
        _candidates.Clear();
        _candidatesById.Clear();

        foreach (Node node in GetTree().GetNodesInGroup(EnemyController.EnemiesGroup))
        {
            if (node is EnemyController enemy && !enemy.IsDead)
            {
                TargetCandidate candidate = enemy.ToCandidate();
                _candidates.Add(candidate);
                _candidatesById[candidate.Id] = enemy;
            }
        }
    }

    private void UpdateTargetMarker(EnemyController? selected)
    {
        if (ReferenceEquals(selected, _currentTarget))
        {
            return;
        }

        _currentTarget?.SetTargeted(false);
        _currentTarget = selected;
        _currentTarget?.SetTargeted(true);
    }

    private void OnAbilityCast(AbilityCastPredictedEvent castEvent)
    {
        if (castEvent.EffectType != AbilityEffectType.Damage)
        {
            return; // Heilung u. Ä. betrifft (noch) nicht die Gegner.
        }

        if (_currentTarget is null || _currentTarget.IsDead)
        {
            return; // Reichweite/Ziel wurden bereits beim Wirken geprüft (AbilityBar).
        }

        _currentTarget.ApplyDamage(castEvent.Magnitude);
        _game.Logger.Debug(
            LogCategory,
            $"{castEvent.AbilityId} trifft Ziel für {castEvent.Magnitude:F0} Schaden (prädiktiv).");
    }
}
