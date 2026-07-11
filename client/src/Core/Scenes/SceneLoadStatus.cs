namespace Aethermoor.Core.Scenes;

/// <summary>
/// Engine-unabhängige Spiegelung des Ladezustands, den ein asynchroner Ressourcenlader
/// meldet. Der Godot-<see cref="SceneRouter"/> bildet den Godot-eigenen Statuswert auf
/// diesen Typ ab, damit die auswertende Logik (<see cref="SceneLoadTracker"/>) Godot-frei
/// und in CI testbar bleibt (siehe ARCHITECTURE §8).
/// </summary>
public enum SceneLoadStatus
{
    /// <summary>Der angeforderte Pfad ist ungültig / keine ladbare Ressource.</summary>
    InvalidResource = 0,

    /// <summary>Der Ladevorgang läuft noch.</summary>
    InProgress = 1,

    /// <summary>Der Ladevorgang ist fehlgeschlagen.</summary>
    Failed = 2,

    /// <summary>Die Ressource ist vollständig geladen und abholbereit.</summary>
    Loaded = 3,
}
