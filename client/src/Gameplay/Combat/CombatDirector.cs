using System.Collections.Generic;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Abilities;
using Aethermoor.Gameplay.Character;
using Aethermoor.Gameplay.Enemies;
using Aethermoor.Gameplay.Targeting;
using Aethermoor.Networking;
using Aethermoor.Networking.Protocol;
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
/// <para>
/// Ist ein <see cref="IMatchClient"/> mit aktivem Match registriert, wird jeder Cast
/// zusätzlich an den Server gesendet (predict-and-confirm): Der Client zeigt die Vorhersage
/// sofort, der Server validiert verbindlich (ADR-0002). Server-Ablehnungen werden pro Frame
/// abgeholt und als <see cref="AbilityCastRejectedEvent"/> für Spieler-Feedback veröffentlicht.
/// </para>
/// <para>
/// Die autoritative Übernahme von Gegner-Leben/-Tod aus den Server-Snapshots (statt lokaler
/// Vorhersage) folgt mit der server-getriebenen Gegner-Iteration; bis dahin bleibt die lokale
/// Auflösung die sichtbare (siehe Roadmap Milestone 5).
/// </para>
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
    private readonly ComboTracker _combos = new();

    private GameBootstrap _game = null!;
    private SmartTargetSelector _selector = null!;
    private LocalCharacterController? _player;
    private EnemyController? _currentTarget;
    private IMatchClient? _match;

    /// <inheritdoc />
    public float DistanceToTarget { get; private set; } = float.PositiveInfinity;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _player = GetNodeOrNull<LocalCharacterController>(PlayerPath);
        _selector = new SmartTargetSelector(MaxTargetRange, ConeHalfAngleDegrees);

        _game.Services.TryGet(out _match); // optional: nur im Netzwerkbetrieb vorhanden
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

        DrainServerCastResults();
    }

    private void DrainServerCastResults()
    {
        if (_match is null)
        {
            return;
        }

        while (_match.TryDequeueCastResult(out CastResultPayload? result) && result is not null)
        {
            if (result.Ok)
            {
                _game.Logger.Debug(LogCategory, $"Server bestätigt: {result.Ability}.");
                continue;
            }

            CastFailureReason reason = CastFailureReasonMapper.FromServerReason(result.Reason);
            _game.Logger.Debug(LogCategory, $"Server lehnt {result.Ability} ab: {reason}.");
            _game.Events.Publish(new AbilityCastRejectedEvent(result.Ability, reason));
        }
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
        SendServerCast(castEvent.Ability);

        switch (castEvent.Ability.EffectType)
        {
            case AbilityEffectType.Heal:
                _player?.Heal(castEvent.Ability.Magnitude);
                break;

            case AbilityEffectType.Damage:
                ApplyDamageToCurrentTarget(castEvent.Ability);
                break;

            default:
                break;
        }
    }

    private void SendServerCast(AbilityDefinition ability)
    {
        if (_match is null || !_match.IsInMatch)
        {
            return; // reiner Lokalbetrieb (Vertikale ohne Server)
        }

        int? target = null;
        if (ability.EffectType == AbilityEffectType.Damage)
        {
            // Nur server-bekannte Ziele (Spawn-ID ≥ 0) senden; rein lokale Gegner nicht.
            if (_currentTarget is null || _currentTarget.ServerSpawnId < 0)
            {
                return;
            }

            target = _currentTarget.ServerSpawnId;
        }

        _match.SendCastRequest(new CastRequestPayload(ability.Id, target));
    }

    private void ApplyDamageToCurrentTarget(AbilityDefinition ability)
    {
        if (_currentTarget is null || _currentTarget.IsDead)
        {
            return; // Reichweite/Ziel wurden bereits beim Wirken geprüft (AbilityBar).
        }

        long targetId = _currentTarget.ToCandidate().Id;
        double now = Time.GetTicksMsec() / 1000.0;

        // Combo (GAME_DESIGN §7): Finisher verbraucht den Marker und verstärkt die Wirkung.
        float damage = ability.Magnitude;
        bool comboTriggered = ability.ConsumesMarker.Length > 0
            && _combos.TryConsumeMarker(targetId, ability.ConsumesMarker, now);
        if (comboTriggered)
        {
            damage *= ability.ComboBonusMultiplier;
        }

        float applied = _currentTarget.ApplyDamage(damage);
        if (applied <= 0f)
        {
            return;
        }

        if (_currentTarget.IsDead)
        {
            _combos.ClearTarget(targetId);
        }
        else if (ability.AppliesMarker.Length > 0)
        {
            _combos.ApplyMarker(targetId, ability.AppliesMarker, now, ability.MarkerDurationSeconds);
        }

        var position = new NumericsVector2(
            _currentTarget.GlobalPosition.X, _currentTarget.GlobalPosition.Y);
        _game.Events.Publish(new CombatNumberEvent(position, applied, CombatNumberKind.DamageDealt));
        _game.Logger.Debug(
            LogCategory,
            $"{ability.Id} trifft für {applied:F0} Schaden{(comboTriggered ? " (COMBO)" : "")} (prädiktiv).");
    }
}
