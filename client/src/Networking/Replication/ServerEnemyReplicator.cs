using System;
using System.Collections.Generic;
using System.Numerics;
using Aethermoor.Networking.Protocol;

namespace Aethermoor.Networking.Replication;

/// <summary>
/// Übernimmt die autoritativen Gegner aus den Server-Snapshots: puffert je Spawn-ID die
/// Positionen für weiche Interpolation (wie Fremdspieler, <see cref="SnapshotBuffer"/>) und
/// hält das serverseitige Leben. Im Netzwerkbetrieb ist damit der Server die Wahrheit über
/// Gegner-Position und -Leben; die lokale Client-KI wird zur reinen Vorhersage (ADR-0002).
/// </summary>
/// <remarks>
/// Engine- und SDK-frei, in CI unit-testbar (ARCHITECTURE §8). Der Godot-Layer speist pro
/// Snapshot <see cref="Apply"/> und fragt pro Frame <see cref="SamplePosition"/> /
/// <see cref="IsAlive"/> ab. Der Server sendet stets alle Spawns (auch tote mit Leben 0),
/// daher gibt es kein Despawn — „tot" ist Leben ≤ 0, „respawnt" ist Leben wieder &gt; 0.
/// </remarks>
public sealed class ServerEnemyReplicator
{
    private readonly double _interpolationDelay;
    private readonly Dictionary<int, SnapshotBuffer> _buffers = new();
    private readonly Dictionary<int, float> _health = new();

    /// <param name="interpolationDelaySeconds">Darstellungsverzögerung für die Interpolation (≥ 0).</param>
    /// <exception cref="ArgumentOutOfRangeException">Bei negativer Verzögerung.</exception>
    public ServerEnemyReplicator(double interpolationDelaySeconds = 0.2)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(interpolationDelaySeconds);
        _interpolationDelay = interpolationDelaySeconds;
    }

    /// <summary>Alle bekannten Spawn-IDs (lebend oder tot).</summary>
    public IReadOnlyCollection<int> Sids => _buffers.Keys;

    /// <summary>Übernimmt die Gegner-Einträge eines Snapshots zum Zeitpunkt <paramref name="snapshotTime"/>.</summary>
    public void Apply(double snapshotTime, IReadOnlyList<EnemySnapshot> enemies)
    {
        ArgumentNullException.ThrowIfNull(enemies);

        foreach (EnemySnapshot enemy in enemies)
        {
            if (!_buffers.TryGetValue(enemy.Sid, out SnapshotBuffer? buffer))
            {
                buffer = new SnapshotBuffer(_interpolationDelay);
                _buffers.Add(enemy.Sid, buffer);
            }

            buffer.Add(new PositionSnapshot(snapshotTime, new Vector2(enemy.X, enemy.Y)));
            _health[enemy.Sid] = enemy.Hp;
        }
    }

    /// <summary>Ob der Gegner lebt (serverseitiges Leben &gt; 0).</summary>
    public bool IsAlive(int sid) => _health.TryGetValue(sid, out float hp) && hp > 0f;

    /// <summary>Serverseitiges Leben des Gegners (0, wenn unbekannt/tot).</summary>
    public float GetHealth(int sid) => _health.GetValueOrDefault(sid);

    /// <summary>
    /// Interpolierte Position des Gegners für den Render-Zeitpunkt, oder <c>null</c>, wenn
    /// die Spawn-ID unbekannt ist oder noch keine Daten vorliegen.
    /// </summary>
    public Vector2? SamplePosition(int sid, double currentTime)
        => _buffers.TryGetValue(sid, out SnapshotBuffer? buffer) ? buffer.Sample(currentTime) : null;

    /// <summary>Verwirft alle gepufferten Gegner (Zonenwechsel, Match-Verlassen).</summary>
    public void Clear()
    {
        _buffers.Clear();
        _health.Clear();
    }
}
