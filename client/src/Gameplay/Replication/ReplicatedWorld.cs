using System;
using System.Collections.Generic;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Input;
using Aethermoor.Networking;
using Aethermoor.Networking.Connection;
using Aethermoor.Networking.Model;
using Aethermoor.Networking.Protocol;
using Aethermoor.Networking.Replication;
using Godot;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.Gameplay.Replication;

/// <summary>
/// Verdrahtet die serverautoritative Bewegung mit der Szene: schickt Joystick-Eingaben durch
/// den <see cref="PredictionReconciler"/> (eigene Figur bewegt sich latenzfrei), sendet sie an
/// das Bewegungs-Match und verarbeitet Server-Snapshots — eigene Figur wird abgeglichen,
/// fremde Spieler laufen über je einen <see cref="SnapshotBuffer"/> interpoliert.
/// </summary>
/// <remarks>
/// <para>
/// Dünne Godot-Schicht: sämtliche Replikations-Logik liegt in den CI-getesteten, engine-freien
/// Bausteinen. Snapshots werden über <see cref="IMatchClient.TryDequeueSnapshot"/> im
/// Physik-Frame abgeholt — dadurch bleibt aller Szenenzugriff auf dem Main-Thread
/// (siehe Threading-Hinweis am <see cref="IMatchClient"/>).
/// </para>
/// <para>
/// Erfordert einen registrierten <see cref="IMatchClient"/>/<see cref="INetworkService"/>
/// (Nakama-Adapter, siehe <c>Networking/README.md</c>); ohne diese bleibt die Szene passiv
/// und protokolliert eine Warnung.
/// </para>
/// </remarks>
public sealed partial class ReplicatedWorld : Node2D
{
    private const string LogCategory = "Net";

    /// <summary>Bewegungstempo in px/s — MUSS <c>MOVE_SPEED</c> im Match-Handler entsprechen.</summary>
    [Export(PropertyHint.Range, "50,1000,10")] public float MoveSpeed { get; set; } = 320f;

    /// <summary>Interpolationsverzögerung für fremde Spieler in Sekunden.</summary>
    [Export(PropertyHint.Range, "0,1,0.05")] public float InterpolationDelay { get; set; } = 0.2f;

    /// <summary>Pfad zur eigenen Spielfigur (Node2D).</summary>
    [Export] public NodePath PlayerPath { get; set; } = new();

    /// <summary>Pfad zum Knoten, der <see cref="IMovementInputSource"/> implementiert.</summary>
    [Export] public NodePath InputSourcePath { get; set; } = new();

    private readonly Dictionary<string, SnapshotBuffer> _remoteBuffers = new();
    private readonly Dictionary<string, Node2D> _remoteAvatars = new();
    private readonly List<string> _departed = new();

    private GameBootstrap _game = null!;
    private PredictionReconciler _reconciler = null!;
    private INetworkService? _network;
    private IMatchClient? _match;
    private IMovementInputSource? _input;
    private Node2D? _playerNode;
    private double _serverClock;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _playerNode = GetNodeOrNull<Node2D>(PlayerPath);
        _input = GetNodeOrNull(InputSourcePath) as IMovementInputSource;

        _reconciler = new PredictionReconciler(
            (position, direction, dt) => position + (direction * MoveSpeed * dt));
        if (_playerNode is not null)
        {
            _reconciler.Reset(new NumericsVector2(_playerNode.Position.X, _playerNode.Position.Y));
        }

        bool hasNetwork = _game.Services.TryGet(out _network);
        bool hasMatch = _game.Services.TryGet(out _match);
        if (!hasNetwork || !hasMatch)
        {
            _game.Logger.Warning(
                LogCategory,
                "Kein Nakama-Dienst registriert — ReplicatedWorld bleibt passiv " +
                "(Umschalten: client/src/Networking/README.md).");
            return;
        }

        _ = SetupNetworkAsync();
    }

    public override void _ExitTree()
    {
        _ = _match?.LeaveMatchAsync();
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_match is null || _network?.Session is null)
        {
            return;
        }

        DrainSnapshots();

        // Eigene Eingabe: sofort vorhersagen (latenzfrei) und an den Server senden.
        float dt = (float)delta;
        NumericsVector2 direction = _input?.MovementVector ?? NumericsVector2.Zero;
        MovementInput applied = _reconciler.ApplyLocalInput(direction, dt);
        if (_match.IsInMatch)
        {
            _match.SendMovementInput(
                new MovementInputPayload(applied.Sequence, direction.X, direction.Y, dt));
        }

        if (_playerNode is not null)
        {
            _playerNode.Position = new Vector2(
                _reconciler.PredictedPosition.X, _reconciler.PredictedPosition.Y);
        }

        _serverClock += delta;
        UpdateRemoteAvatars();
    }

    private async System.Threading.Tasks.Task SetupNetworkAsync()
    {
        try
        {
            if (_network!.State is ConnectionState.Disconnected or ConnectionState.Failed)
            {
                await _network.ConnectAsync(new AuthCredentials(BuildDeviceId()));
            }

            if (_network.State != ConnectionState.Connected)
            {
                _game.Logger.Error(LogCategory, "Verbindung nicht hergestellt — Match-Beitritt übersprungen.");
                return;
            }

            await _match!.JoinMovementMatchAsync();
        }
        catch (Exception ex)
        {
            _game.Logger.Error(LogCategory, $"Netzwerk-Setup fehlgeschlagen: {ex.Message}");
        }
    }

    private static string BuildDeviceId()
    {
        // Stabile Gerätekennung; Fallback auf Zufallskennung (nur Sitzungsdauer), falls die
        // Plattform keine liefert. Präfix sichert Nakamas Mindestlänge für Device-IDs.
        string unique = OS.GetUniqueId();
        if (string.IsNullOrEmpty(unique))
        {
            unique = Guid.NewGuid().ToString("N");
        }

        return $"aethermoor-{unique}";
    }

    private void DrainSnapshots()
    {
        while (_match!.TryDequeueSnapshot(out MovementSnapshot? snapshot))
        {
            ApplySnapshot(snapshot!);
        }
    }

    private void ApplySnapshot(MovementSnapshot snapshot)
    {
        _serverClock = Math.Max(_serverClock, snapshot.Time);
        string ownId = _network!.Session!.UserId;

        foreach (PlayerSnapshot player in snapshot.Players)
        {
            if (player.Id == ownId)
            {
                // Autoritative Korrektur + Replay der unbestätigten Eingaben.
                _reconciler.Reconcile(player.Ack, new NumericsVector2(player.X, player.Y));
                continue;
            }

            if (!_remoteBuffers.TryGetValue(player.Id, out SnapshotBuffer? buffer))
            {
                buffer = new SnapshotBuffer(InterpolationDelay);
                _remoteBuffers.Add(player.Id, buffer);
            }

            buffer.Add(new PositionSnapshot(snapshot.Time, new NumericsVector2(player.X, player.Y)));
        }

        RemoveDepartedPlayers(snapshot);
    }

    private void RemoveDepartedPlayers(MovementSnapshot snapshot)
    {
        _departed.Clear();
        foreach (string id in _remoteBuffers.Keys)
        {
            bool present = false;
            foreach (PlayerSnapshot player in snapshot.Players)
            {
                if (player.Id == id)
                {
                    present = true;
                    break;
                }
            }

            if (!present)
            {
                _departed.Add(id);
            }
        }

        foreach (string id in _departed)
        {
            _remoteBuffers.Remove(id);
            if (_remoteAvatars.Remove(id, out Node2D? avatar))
            {
                avatar.QueueFree();
            }
        }
    }

    private void UpdateRemoteAvatars()
    {
        foreach (KeyValuePair<string, SnapshotBuffer> entry in _remoteBuffers)
        {
            NumericsVector2? position = entry.Value.Sample(_serverClock);
            if (position is null)
            {
                continue;
            }

            if (!_remoteAvatars.TryGetValue(entry.Key, out Node2D? avatar))
            {
                avatar = CreateRemoteAvatar();
                _remoteAvatars.Add(entry.Key, avatar);
                AddChild(avatar);
            }

            avatar.Position = new Vector2(position.Value.X, position.Value.Y);
        }
    }

    private static Node2D CreateRemoteAvatar()
    {
        // Platzhalter-Avatar für fremde Spieler (orange), bis echte Charaktermodelle kommen.
        var avatar = new Node2D();
        avatar.AddChild(new ColorRect
        {
            Position = new Vector2(-24f, -24f),
            Size = new Vector2(48f, 48f),
            Color = new Color(1f, 0.6f, 0.2f),
        });
        return avatar;
    }
}
