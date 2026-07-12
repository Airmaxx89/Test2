using System;
using System.Collections.Generic;
using System.Numerics;

namespace Aethermoor.Networking.Replication;

/// <summary>Ein lokal angewendeter, noch nicht serverbestätigter Bewegungs-Input.</summary>
/// <param name="Sequence">Fortlaufende Eingabenummer (wird an den Server mitgesendet).</param>
/// <param name="Direction">Normalisierter Bewegungsvektor des Frames.</param>
/// <param name="DeltaSeconds">Frame-Zeit in Sekunden.</param>
public readonly record struct MovementInput(uint Sequence, Vector2 Direction, float DeltaSeconds);

/// <summary>
/// Bewegungsschritt-Funktion: wendet einen Input auf eine Position an. Wird injiziert, damit
/// Client-Prediction und autoritative Serverlogik dieselbe Formel teilen können.
/// </summary>
public delegate Vector2 MovementStep(Vector2 position, Vector2 direction, float deltaSeconds);

/// <summary>
/// Client-Prediction mit Server-Reconciliation für die eigene Spielfigur: Eingaben werden
/// sofort lokal angewendet (keine spürbare Latenz) und gepuffert; bestätigt der Server einen
/// älteren Zustand, wird ab dessen Position neu aufgesetzt und alle noch unbestätigten
/// Eingaben werden erneut angewendet. Divergenzen durch Latenz korrigieren sich so, ohne dass
/// die Steuerung „gummiartig" wirkt.
/// </summary>
/// <remarks>
/// Engine- und SDK-frei, deterministisch und in CI unit-getestet (ARCHITECTURE §5, §8). Der
/// Server bleibt autoritativ: Der Client rechnet nur vor, niemals verbindlich (ADR-0002).
/// </remarks>
public sealed class PredictionReconciler
{
    private readonly MovementStep _step;
    private readonly Queue<MovementInput> _pending = new();
    private readonly int _maxPendingInputs;
    private uint _nextSequence = 1;

    /// <param name="step">Gemeinsame Bewegungsformel (Pflicht).</param>
    /// <param name="maxPendingInputs">
    /// Obergrenze gepufferter Eingaben (&gt; 0). Läuft der Puffer voll (Server antwortet lange
    /// nicht), fallen die ältesten Eingaben heraus — die nächste Bestätigung korrigiert dann hart.
    /// </param>
    /// <exception cref="ArgumentNullException">Wenn <paramref name="step"/> null ist.</exception>
    /// <exception cref="ArgumentOutOfRangeException">Wenn die Obergrenze nicht positiv ist.</exception>
    public PredictionReconciler(MovementStep step, int maxPendingInputs = 128)
    {
        ArgumentNullException.ThrowIfNull(step);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(maxPendingInputs);

        _step = step;
        _maxPendingInputs = maxPendingInputs;
    }

    /// <summary>Aktuell vorhergesagte Position der eigenen Figur.</summary>
    public Vector2 PredictedPosition { get; private set; }

    /// <summary>Anzahl noch unbestätigter Eingaben.</summary>
    public int PendingCount => _pending.Count;

    /// <summary>Setzt die Vorhersage hart auf eine Position (Spawn, Teleport, Zonenwechsel).</summary>
    public void Reset(Vector2 position)
    {
        _pending.Clear();
        PredictedPosition = position;
    }

    /// <summary>
    /// Wendet eine lokale Eingabe sofort auf die Vorhersage an und puffert sie für die
    /// spätere Abstimmung mit dem Server.
    /// </summary>
    /// <returns>Die gepufferte Eingabe inklusive vergebener Sequenznummer (für den Versand).</returns>
    public MovementInput ApplyLocalInput(Vector2 direction, float deltaSeconds)
    {
        var input = new MovementInput(_nextSequence++, direction, deltaSeconds);

        _pending.Enqueue(input);
        while (_pending.Count > _maxPendingInputs)
        {
            _pending.Dequeue();
        }

        PredictedPosition = _step(PredictedPosition, input.Direction, input.DeltaSeconds);
        return input;
    }

    /// <summary>
    /// Verarbeitet einen autoritativen Serverzustand: verwirft alle bis
    /// <paramref name="acknowledgedSequence"/> bestätigten Eingaben, setzt auf der
    /// Serverposition auf und wendet die verbleibenden Eingaben erneut an.
    /// </summary>
    /// <returns>Die korrigierte vorhergesagte Position.</returns>
    public Vector2 Reconcile(uint acknowledgedSequence, Vector2 serverPosition)
    {
        while (_pending.Count > 0 && _pending.Peek().Sequence <= acknowledgedSequence)
        {
            _pending.Dequeue();
        }

        Vector2 position = serverPosition;
        foreach (MovementInput input in _pending)
        {
            position = _step(position, input.Direction, input.DeltaSeconds);
        }

        PredictedPosition = position;
        return position;
    }
}
