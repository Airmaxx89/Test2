using System.Collections.Generic;
using Aethermoor.Core.Bootstrap;
using Godot;

namespace Aethermoor.Gameplay.Zones;

/// <summary>
/// Verwaltet die Spawnpunkte einer Zone: initiale Bevölkerung und Respawns über den
/// getesteten, engine-freien <see cref="RespawnScheduler"/>. Spawnpunkte sind Kind-Knoten —
/// die Zone selbst ist damit reine Szenen-Datei und ohne Codeänderung erweiterbar
/// (neuer Kontinent/neue Zone = neue Szene, ARCHITECTURE §4).
/// </summary>
public sealed partial class ZoneController : Node2D
{
    private const string LogCategory = "World";

    /// <summary>Pfad zur Spielfigur (wird an alle Spawnpunkte gereicht).</summary>
    [Export] public NodePath PlayerPath { get; set; } = new();

    private readonly RespawnScheduler _scheduler = new();
    private readonly List<SpawnPoint> _spawnPoints = new();
    private readonly List<int> _due = new();

    private GameBootstrap _game = null!;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        Node2D? player = GetNodeOrNull<Node2D>(PlayerPath);

        foreach (Node child in GetChildren())
        {
            if (child is SpawnPoint spawnPoint)
            {
                spawnPoint.Setup(player, OnSpawnPointCleared);
                _spawnPoints.Add(spawnPoint);
                spawnPoint.Spawn();
            }
        }

        _game.Logger.Info(LogCategory, $"Zone bevölkert: {_spawnPoints.Count} Spawnpunkte.");
    }

    public override void _PhysicsProcess(double delta)
    {
        _due.Clear();
        _scheduler.CollectDue(NowSeconds(), _due);
        foreach (int index in _due)
        {
            _spawnPoints[index].Spawn();
        }
    }

    private void OnSpawnPointCleared(SpawnPoint spawnPoint)
    {
        int index = _spawnPoints.IndexOf(spawnPoint);
        if (index >= 0)
        {
            _scheduler.Schedule(index, NowSeconds(), spawnPoint.RespawnDelaySeconds);
        }
    }

    private static double NowSeconds() => Time.GetTicksMsec() / 1000.0;
}
