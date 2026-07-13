using System;
using Aethermoor.Gameplay.Enemies;
using Godot;

namespace Aethermoor.Gameplay.Zones;

/// <summary>
/// Ein Gegner-Spawnpunkt einer Zone: erzeugt seinen Gegner aus Daten
/// (<see cref="EnemyResource"/>-Pfad), meldet dessen Tod an die Zone und respawnt auf
/// Anforderung. Position des Knotens = Heimatpunkt des Gegners; Zonen sind damit reine
/// Szenen-Daten (neuer Spawn = neuer Knoten, kein Code — ARCHITECTURE §4).
/// </summary>
public sealed partial class SpawnPoint : Node2D
{
    /// <summary>Ressourcenpfad der Gegnerdefinition (<c>res://…tres</c>).</summary>
    [Export] public string EnemyDefinitionPath { get; set; } = string.Empty;

    /// <summary>Patrouillen-Wegpunkte relativ zum Spawnpunkt (leer = stehen).</summary>
    [Export] public Vector2[] PatrolOffsets { get; set; } = Array.Empty<Vector2>();

    /// <summary>Wartezeit bis zum Respawn nach dem Tod in Sekunden.</summary>
    [Export(PropertyHint.Range, "1,600,1")] public float RespawnDelaySeconds { get; set; } = 20f;

    private Node2D? _player;
    private Action<SpawnPoint>? _onCleared;
    private EnemyController? _current;

    /// <summary>Verdrahtung durch die besitzende Zone (vor dem ersten <see cref="Spawn"/>).</summary>
    public void Setup(Node2D? player, Action<SpawnPoint> onCleared)
    {
        _player = player;
        _onCleared = onCleared;
    }

    /// <summary>
    /// Erzeugt den Gegner an diesem Punkt. Ein etwaiger Leichnam des Vorgängers wird
    /// entfernt; lebt der aktuelle Gegner noch, passiert nichts.
    /// </summary>
    public void Spawn()
    {
        if (_current is not null && !_current.IsDead)
        {
            return;
        }

        _current?.QueueFree(); // Leichnam des Vorgängers abräumen

        var enemy = new EnemyController();
        enemy.Configure(EnemyDefinitionPath, _player, PatrolOffsets);
        enemy.Defeated += OnEnemyDefeated;
        AddChild(enemy);
        _current = enemy;
    }

    private void OnEnemyDefeated()
    {
        // Leichnam bleibt sichtbar liegen; die Zone plant den Respawn.
        _onCleared?.Invoke(this);
    }
}
