using Aethermoor.Core.Events;

namespace Aethermoor.Core.Scenes;

/// <summary>
/// Wird veröffentlicht, sobald ein Szenenwechsel angefordert und der Ladevorgang gestartet
/// wurde. UI (z. B. Ladebildschirm) kann daraufhin einen Fortschrittsbalken einblenden.
/// </summary>
public readonly record struct SceneLoadStartedEvent(string ScenePath) : IGameEvent;

/// <summary>
/// Fortschrittsmeldung eines laufenden Szenenladevorgangs. <see cref="Progress"/> liegt im
/// Bereich 0..1 und ist monoton steigend.
/// </summary>
public readonly record struct SceneLoadProgressEvent(string ScenePath, float Progress) : IGameEvent;

/// <summary>
/// Wird veröffentlicht, nachdem die Zielszene erfolgreich geladen und aktiviert wurde.
/// </summary>
public readonly record struct SceneLoadCompletedEvent(string ScenePath) : IGameEvent;

/// <summary>
/// Wird veröffentlicht, wenn ein Szenenwechsel fehlschlägt. <see cref="Reason"/> beschreibt
/// die Ursache für Protokollierung und ggf. eine Wiederholen-UI.
/// </summary>
public readonly record struct SceneLoadFailedEvent(string ScenePath, string Reason) : IGameEvent;
