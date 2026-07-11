namespace Aethermoor.Core.Scenes;

/// <summary>
/// Lebenszyklus-Phase eines vom <see cref="SceneLoadTracker"/> verfolgten Szenenladevorgangs.
/// Bewusst getrennt vom rohen <see cref="SceneLoadStatus"/> der Engine, da hier zusätzlich
/// zwischen „noch nichts angefordert" (<see cref="Idle"/>) und den Endzuständen unterschieden
/// wird.
/// </summary>
public enum SceneLoadPhase
{
    /// <summary>Kein Ladevorgang aktiv.</summary>
    Idle,

    /// <summary>Ein Ladevorgang läuft.</summary>
    InProgress,

    /// <summary>Der Ladevorgang wurde erfolgreich abgeschlossen (Endzustand).</summary>
    Succeeded,

    /// <summary>Der Ladevorgang ist fehlgeschlagen (Endzustand).</summary>
    Failed,
}
