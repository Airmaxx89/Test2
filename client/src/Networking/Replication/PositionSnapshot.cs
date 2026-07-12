using System.Numerics;

namespace Aethermoor.Networking.Replication;

/// <summary>
/// Zeitgestempelte Positions-Momentaufnahme einer entfernten Entität, wie sie der Server
/// liefert. Grundlage der Snapshot-Interpolation im <see cref="SnapshotBuffer"/>.
/// </summary>
/// <param name="Timestamp">Serverzeit der Momentaufnahme in Sekunden.</param>
/// <param name="Position">Position der Entität zu diesem Zeitpunkt.</param>
public readonly record struct PositionSnapshot(double Timestamp, Vector2 Position);
