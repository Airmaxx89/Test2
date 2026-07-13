using Aethermoor.Core.Events;

namespace Aethermoor.Gameplay.Enemies;

/// <summary>
/// Wird veröffentlicht, wenn ein Gegner (prädiktiv) besiegt wurde. Quests, Erfolge und
/// Loot docken hier an, ohne die Gegner-Knoten zu kennen — wichtig, weil Gegner über
/// Spawnpunkte dynamisch entstehen und vergehen.
/// </summary>
/// <param name="EnemyId">Typ-Kennung des Gegners (<see cref="EnemyDefinition.Id"/>).</param>
public readonly record struct EnemyDefeatedEvent(string EnemyId) : IGameEvent;
