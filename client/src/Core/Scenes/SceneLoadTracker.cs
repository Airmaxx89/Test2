using System;

namespace Aethermoor.Core.Scenes;

/// <summary>
/// Engine-freie Zustandsmaschine für genau einen asynchronen Szenenladevorgang. Übersetzt
/// die rohen <see cref="SceneLoadStatus"/>-Meldungen der Engine in eine klare
/// <see cref="SceneLoadPhase"/> und normalisiert den Fortschritt (geklemmt auf 0..1 und
/// monoton steigend), damit die UI keine springenden oder rückläufigen Balken zeigt.
/// </summary>
/// <remarks>
/// Bewusst Godot-frei gehalten und daher in CI unit-testbar (siehe ARCHITECTURE §8). Der
/// Godot-<see cref="SceneRouter"/> hält eine Instanz und speist sie mit den Poll-Ergebnissen
/// des Ressourcenladers.
/// </remarks>
public sealed class SceneLoadTracker
{
    /// <summary>Pfad der aktuell verfolgten Szene, oder <c>null</c> wenn <see cref="Idle"/>.</summary>
    public string? TargetPath { get; private set; }

    /// <summary>Normalisierter Fortschritt im Bereich 0..1 (monoton steigend).</summary>
    public float Progress { get; private set; }

    /// <summary>Aktuelle Phase des Ladevorgangs.</summary>
    public SceneLoadPhase Phase { get; private set; } = SceneLoadPhase.Idle;

    /// <summary>
    /// Startet die Verfolgung eines neuen Ladevorgangs.
    /// </summary>
    /// <exception cref="ArgumentException">Wenn <paramref name="targetPath"/> leer/null ist.</exception>
    /// <exception cref="InvalidOperationException">
    /// Wenn bereits ein Ladevorgang läuft (jeweils nur einer gleichzeitig).
    /// </exception>
    public void Begin(string targetPath)
    {
        ArgumentException.ThrowIfNullOrEmpty(targetPath);

        if (Phase == SceneLoadPhase.InProgress)
        {
            throw new InvalidOperationException(
                $"Es läuft bereits ein Ladevorgang zu '{TargetPath}'.");
        }

        TargetPath = targetPath;
        Progress = 0f;
        Phase = SceneLoadPhase.InProgress;
    }

    /// <summary>
    /// Verarbeitet einen Poll-Bericht der Engine und liefert die daraus resultierende Phase.
    /// </summary>
    /// <param name="status">Der von der Engine gemeldete Rohstatus.</param>
    /// <param name="engineProgress">Der von der Engine gemeldete Fortschritt (0..1).</param>
    /// <exception cref="InvalidOperationException">
    /// Wenn kein Ladevorgang aktiv ist (zuvor <see cref="Begin"/> aufrufen).
    /// </exception>
    public SceneLoadPhase Report(SceneLoadStatus status, float engineProgress)
    {
        if (Phase != SceneLoadPhase.InProgress)
        {
            throw new InvalidOperationException(
                "Report ist nur während eines laufenden Ladevorgangs zulässig — zuvor Begin aufrufen.");
        }

        switch (status)
        {
            case SceneLoadStatus.InProgress:
                Progress = ClampMonotonic(engineProgress);
                break;

            case SceneLoadStatus.Loaded:
                Progress = 1f;
                Phase = SceneLoadPhase.Succeeded;
                break;

            case SceneLoadStatus.Failed:
            case SceneLoadStatus.InvalidResource:
            default:
                Phase = SceneLoadPhase.Failed;
                break;
        }

        return Phase;
    }

    /// <summary>Setzt den Tracker in den Ausgangszustand zurück (nach Ab- oder Fehlschluss).</summary>
    public void Reset()
    {
        TargetPath = null;
        Progress = 0f;
        Phase = SceneLoadPhase.Idle;
    }

    private float ClampMonotonic(float value)
    {
        float clamped = Math.Clamp(value, 0f, 1f);
        return clamped < Progress ? Progress : clamped;
    }
}
