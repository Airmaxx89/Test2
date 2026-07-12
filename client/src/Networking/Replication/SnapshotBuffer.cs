using System;
using System.Collections.Generic;
using System.Numerics;

namespace Aethermoor.Networking.Replication;

/// <summary>
/// Puffer für zeitgestempelte Server-Snapshots einer entfernten Entität mit Interpolation
/// „in der Vergangenheit": Dargestellt wird der Zustand von vor <c>interpolationDelay</c>
/// Sekunden, sodass zwischen zwei bereits empfangenen Snapshots geglättet werden kann.
/// Entfernte Spieler bewegen sich dadurch flüssig statt ruckhaft von Paket zu Paket.
/// </summary>
/// <remarks>
/// <para>
/// Engine- und SDK-frei und damit in CI unit-testbar (ARCHITECTURE §8). Der Godot-Layer
/// füttert den Puffer aus Netzwerknachrichten und fragt pro Frame <see cref="Sample"/> ab.
/// </para>
/// <para>
/// Verspätet eintreffende (ältere) Snapshots werden einsortiert; Duplikate desselben
/// Zeitstempels ersetzen den vorhandenen Eintrag. Die Kapazität ist begrenzt, älteste
/// Einträge fallen heraus (kein unbegrenztes Wachstum, CODING_STANDARDS §7).
/// </para>
/// </remarks>
public sealed class SnapshotBuffer
{
    private readonly List<PositionSnapshot> _snapshots = new();
    private readonly int _capacity;
    private readonly double _interpolationDelay;

    /// <param name="interpolationDelaySeconds">Darstellungsverzögerung in Sekunden (≥ 0).</param>
    /// <param name="capacity">Maximal vorgehaltene Snapshots (≥ 2).</param>
    /// <exception cref="ArgumentOutOfRangeException">Bei ungültigen Parametern.</exception>
    public SnapshotBuffer(double interpolationDelaySeconds = 0.1, int capacity = 32)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(interpolationDelaySeconds);
        ArgumentOutOfRangeException.ThrowIfLessThan(capacity, 2);

        _interpolationDelay = interpolationDelaySeconds;
        _capacity = capacity;
    }

    /// <summary>Anzahl aktuell gepufferter Snapshots.</summary>
    public int Count => _snapshots.Count;

    /// <summary>Fügt einen Snapshot zeitlich einsortiert hinzu.</summary>
    public void Add(PositionSnapshot snapshot)
    {
        int index = _snapshots.FindLastIndex(s => s.Timestamp <= snapshot.Timestamp);

        if (index >= 0 && _snapshots[index].Timestamp == snapshot.Timestamp)
        {
            _snapshots[index] = snapshot; // gleicher Zeitstempel -> ersetzen
        }
        else
        {
            _snapshots.Insert(index + 1, snapshot);
        }

        while (_snapshots.Count > _capacity)
        {
            _snapshots.RemoveAt(0); // ältesten Eintrag verwerfen
        }
    }

    /// <summary>
    /// Liefert die interpolierte Position für den Render-Zeitpunkt
    /// (<paramref name="currentTime"/> − Interpolationsverzögerung), oder <c>null</c> bei
    /// leerem Puffer. Außerhalb des gepufferten Bereichs wird auf den ältesten bzw. neuesten
    /// Snapshot geklemmt (keine Extrapolation — verhindert sichtbares Überschießen).
    /// </summary>
    public Vector2? Sample(double currentTime)
    {
        if (_snapshots.Count == 0)
        {
            return null;
        }

        double renderTime = currentTime - _interpolationDelay;

        if (renderTime <= _snapshots[0].Timestamp)
        {
            return _snapshots[0].Position;
        }

        PositionSnapshot newest = _snapshots[^1];
        if (renderTime >= newest.Timestamp)
        {
            return newest.Position;
        }

        // Umschließendes Paar suchen und linear interpolieren.
        for (int i = 1; i < _snapshots.Count; i++)
        {
            PositionSnapshot from = _snapshots[i - 1];
            PositionSnapshot to = _snapshots[i];
            if (renderTime > to.Timestamp)
            {
                continue;
            }

            double span = to.Timestamp - from.Timestamp;
            float t = span <= double.Epsilon ? 1f : (float)((renderTime - from.Timestamp) / span);
            return Vector2.Lerp(from.Position, to.Position, t);
        }

        return newest.Position; // theoretisch unerreichbar (oben geklemmt)
    }

    /// <summary>Verwirft alle gepufferten Snapshots (z. B. bei Teleport oder Zonenwechsel).</summary>
    public void Clear() => _snapshots.Clear();
}
