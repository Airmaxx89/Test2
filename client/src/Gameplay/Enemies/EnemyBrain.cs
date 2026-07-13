using System;
using System.Collections.Generic;
using System.Numerics;

namespace Aethermoor.Gameplay.Enemies;

/// <summary>
/// Engine-freie KI-Zustandsmaschine eines Standard-Gegners: Patrouille → Aggro →
/// Verfolgen/Angriff → Heimkehr (GAME_DESIGN §8). Pro Tick liefert <see cref="Decide"/>
/// eine Bewegungs-/Angriffsentscheidung; sämtliche Übergangsregeln sind deterministisch
/// und in CI getestet.
/// </summary>
/// <remarks>
/// <para>Regeln:</para>
/// <list type="bullet">
/// <item>Aggro ist „klebrig": Einmal in Verfolgung, bleibt der Gegner dran, auch wenn der
/// Spieler den Aggro-Radius verlässt — bis die <b>Leine</b> reißt (Distanz zum Heimatpunkt
/// überschreitet <see cref="EnemyDefinition.LeashRadius"/>) oder kein Ziel mehr existiert.</item>
/// <item>Während der Heimkehr wird Aggro ignoriert (klassischer MMO-Reset, verhindert
/// endloses Kiten); am Heimatpunkt beginnt wieder die Patrouille.</item>
/// <item>Die Patrouillenroute ist datengetrieben (Wegpunkte relativ zum Heimatpunkt);
/// ohne Route steht der Gegner am Heimatpunkt.</item>
/// </list>
/// <para>
/// Serverseitig wird dieselbe Logik später autoritativ ausgeführt; die Client-Instanz dient
/// bis dahin der lokalen Vertikale (ADR-0002 unverändert).
/// </para>
/// </remarks>
public sealed class EnemyBrain
{
    /// <summary>Distanz, ab der ein Weg-/Heimatpunkt als erreicht gilt (verhindert Zittern).</summary>
    private const float ArrivalEpsilon = 8f;

    private readonly EnemyDefinition _definition;
    private readonly Vector2 _home;
    private readonly IReadOnlyList<Vector2> _patrolOffsets;
    private int _patrolIndex;

    /// <param name="definition">Verhaltensparameter des Gegnertyps.</param>
    /// <param name="home">Heimatpunkt (Spawn) in Weltkoordinaten.</param>
    /// <param name="patrolOffsets">Patrouillen-Wegpunkte relativ zum Heimatpunkt (darf leer sein).</param>
    public EnemyBrain(EnemyDefinition definition, Vector2 home, IReadOnlyList<Vector2> patrolOffsets)
    {
        ArgumentNullException.ThrowIfNull(definition);
        ArgumentNullException.ThrowIfNull(patrolOffsets);

        _definition = definition;
        _home = home;
        _patrolOffsets = patrolOffsets;
    }

    /// <summary>Aktueller KI-Zustand.</summary>
    public EnemyAiState State { get; private set; } = EnemyAiState.Patrol;

    /// <summary>
    /// Trifft die Entscheidung für einen Tick.
    /// </summary>
    /// <param name="selfPosition">Eigene Position.</param>
    /// <param name="playerPosition">Position des nächsten angreifbaren Spielers, oder <c>null</c>.</param>
    public EnemyAiDecision Decide(Vector2 selfPosition, Vector2? playerPosition)
    {
        if (State == EnemyAiState.Return)
        {
            return ContinueReturning(selfPosition);
        }

        bool hasAggro = State is EnemyAiState.Chase or EnemyAiState.Attack;

        if (playerPosition is null)
        {
            // Ziel weg (tot/außer Spiel): laufende Verfolgung abbrechen, sonst weiter patrouillieren.
            return hasAggro ? StartReturning(selfPosition) : ContinuePatrolling(selfPosition);
        }

        Vector2 player = playerPosition.Value;
        float distanceToPlayer = Vector2.Distance(selfPosition, player);

        if (!hasAggro && distanceToPlayer > _definition.AggroRadius)
        {
            return ContinuePatrolling(selfPosition);
        }

        // Aggro (neu oder klebrig): Leine prüfen, dann angreifen oder verfolgen.
        if (Vector2.Distance(selfPosition, _home) > _definition.LeashRadius)
        {
            return StartReturning(selfPosition);
        }

        if (distanceToPlayer <= _definition.AttackRange)
        {
            State = EnemyAiState.Attack;
            return new EnemyAiDecision(State, Vector2.Zero, WantsToAttack: true);
        }

        State = EnemyAiState.Chase;
        return new EnemyAiDecision(State, DirectionTo(selfPosition, player), WantsToAttack: false);
    }

    private EnemyAiDecision StartReturning(Vector2 selfPosition)
    {
        State = EnemyAiState.Return;
        return ContinueReturning(selfPosition);
    }

    private EnemyAiDecision ContinueReturning(Vector2 selfPosition)
    {
        if (Vector2.Distance(selfPosition, _home) <= ArrivalEpsilon)
        {
            State = EnemyAiState.Patrol;
            return ContinuePatrolling(selfPosition);
        }

        return new EnemyAiDecision(EnemyAiState.Return, DirectionTo(selfPosition, _home), false);
    }

    private EnemyAiDecision ContinuePatrolling(Vector2 selfPosition)
    {
        State = EnemyAiState.Patrol;

        if (_patrolOffsets.Count == 0)
        {
            // Keine Route: am Heimatpunkt stehen (bzw. dorthin zurückfinden).
            Vector2 toHome = Vector2.Distance(selfPosition, _home) > ArrivalEpsilon
                ? DirectionTo(selfPosition, _home)
                : Vector2.Zero;
            return new EnemyAiDecision(State, toHome, false);
        }

        Vector2 waypoint = _home + _patrolOffsets[_patrolIndex];
        if (Vector2.Distance(selfPosition, waypoint) <= ArrivalEpsilon)
        {
            _patrolIndex = (_patrolIndex + 1) % _patrolOffsets.Count;
            waypoint = _home + _patrolOffsets[_patrolIndex];
        }

        return new EnemyAiDecision(State, DirectionTo(selfPosition, waypoint), false);
    }

    private static Vector2 DirectionTo(Vector2 from, Vector2 to)
    {
        Vector2 delta = to - from;
        float length = delta.Length();
        return length <= float.Epsilon ? Vector2.Zero : delta / length;
    }
}
