using System;
using Aethermoor.Core.Diagnostics;
using Aethermoor.Core.Events;
using Aethermoor.Core.Services;
using Godot;

namespace Aethermoor.Core.Scenes;

/// <summary>
/// Zentraler Dienst für asynchrone Szenenwechsel. Nutzt den threaded-Ladepfad der Engine
/// (<see cref="ResourceLoader"/>), sodass der Hauptthread nicht blockiert und ein
/// Ladebildschirm flüssig einen Fortschrittsbalken anzeigen kann — wichtig für gefühlte
/// Ladezeiten auf Mobilgeräten (siehe GAME_DESIGN §15).
/// </summary>
/// <remarks>
/// <para>
/// Bewusst als schlanke Engine-Adapterschicht ausgelegt: Die eigentliche Zustands- und
/// Fortschrittslogik lebt Godot-frei im <see cref="SceneLoadTracker"/> und ist damit in CI
/// getestet. Dieser Dienst pollt den Lader pro Frame (<see cref="Tick"/>), übersetzt den
/// Rohstatus und veröffentlicht Ergebnisse über den <see cref="EventBus"/>.
/// </para>
/// <para>
/// Kein Godot-<c>Node</c>, damit keine Engine-Konstruktionszwänge entstehen: Der
/// <see cref="Bootstrap.GameBootstrap"/> instanziiert den Dienst mit dem aktiven
/// <see cref="SceneTree"/> und ruft <see cref="Tick"/> in seinem eigenen Frame-Update auf.
/// </para>
/// </remarks>
public sealed class SceneRouter : IService
{
    private const string LogCategory = "Scenes";

    private readonly SceneTree _tree;
    private readonly EventBus _events;
    private readonly IGameLogger _logger;
    private readonly SceneLoadTracker _tracker = new();

    public SceneRouter(SceneTree tree, EventBus events, IGameLogger logger)
    {
        ArgumentNullException.ThrowIfNull(tree);
        ArgumentNullException.ThrowIfNull(events);
        ArgumentNullException.ThrowIfNull(logger);

        _tree = tree;
        _events = events;
        _logger = logger;
    }

    /// <summary>Ob derzeit ein Szenenwechsel läuft.</summary>
    public bool IsLoading => _tracker.Phase == SceneLoadPhase.InProgress;

    public void Initialize()
    {
        // Kein Aufbau nötig — der Dienst wird bei Bedarf über ChangeScene aktiviert.
    }

    public void Shutdown()
    {
        // Ein laufender threaded-Ladevorgang wird von der Engine mit dem Baum abgeräumt.
        _tracker.Reset();
    }

    /// <summary>
    /// Fordert den asynchronen Wechsel zur angegebenen Szene an. Ein bereits laufender
    /// Wechsel hat Vorrang; weitere Anforderungen werden bis zu dessen Abschluss ignoriert.
    /// </summary>
    /// <param name="scenePath">Ressourcenpfad der Zielszene (z. B. <c>res://scenes/MainMenu.tscn</c>).</param>
    public void ChangeScene(string scenePath)
    {
        ArgumentException.ThrowIfNullOrEmpty(scenePath);

        if (IsLoading)
        {
            _logger.Warning(
                LogCategory,
                $"Wechsel zu '{scenePath}' ignoriert — Ladevorgang zu '{_tracker.TargetPath}' läuft noch.");
            return;
        }

        Error request = ResourceLoader.LoadThreadedRequest(scenePath);
        if (request != Error.Ok)
        {
            string reason = $"LoadThreadedRequest fehlgeschlagen: {request}";
            _logger.Error(LogCategory, $"'{scenePath}': {reason}");
            _events.Publish(new SceneLoadFailedEvent(scenePath, reason));
            return;
        }

        _tracker.Begin(scenePath);
        _logger.Info(LogCategory, $"Szenenwechsel gestartet: '{scenePath}'.");
        _events.Publish(new SceneLoadStartedEvent(scenePath));
    }

    /// <summary>
    /// Pro-Frame-Aktualisierung: pollt den Ladefortschritt und treibt den Zustandsübergang
    /// voran. Bei Inaktivität ein günstiger No-Op.
    /// </summary>
    public void Tick()
    {
        if (!IsLoading)
        {
            return;
        }

        string path = _tracker.TargetPath!; // In der Phase InProgress garantiert gesetzt.

        var progressOut = new Godot.Collections.Array();
        ResourceLoader.ThreadLoadStatus engineStatus =
            ResourceLoader.LoadThreadedGetStatus(path, progressOut);
        float ratio = progressOut.Count > 0 ? progressOut[0].AsSingle() : 0f;

        SceneLoadPhase phase = _tracker.Report(MapStatus(engineStatus), ratio);

        switch (phase)
        {
            case SceneLoadPhase.InProgress:
                _events.Publish(new SceneLoadProgressEvent(path, _tracker.Progress));
                break;

            case SceneLoadPhase.Succeeded:
                ActivateLoadedScene(path);
                break;

            case SceneLoadPhase.Failed:
                _logger.Error(LogCategory, $"Laden von '{path}' fehlgeschlagen (Engine-Status: {engineStatus}).");
                _events.Publish(new SceneLoadFailedEvent(path, $"ThreadLoadStatus: {engineStatus}"));
                _tracker.Reset();
                break;

            case SceneLoadPhase.Idle:
            default:
                break;
        }
    }

    private void ActivateLoadedScene(string path)
    {
        if (ResourceLoader.LoadThreadedGet(path) is not PackedScene packed)
        {
            string reason = "Geladene Ressource ist keine PackedScene.";
            _logger.Error(LogCategory, $"'{path}': {reason}");
            _events.Publish(new SceneLoadFailedEvent(path, reason));
            _tracker.Reset();
            return;
        }

        // Fortschritt sauber auf 100 % melden, bevor die Szene ausgetauscht wird.
        _events.Publish(new SceneLoadProgressEvent(path, 1f));

        Error swap = _tree.ChangeSceneToPacked(packed);
        if (swap != Error.Ok)
        {
            string reason = $"ChangeSceneToPacked fehlgeschlagen: {swap}";
            _logger.Error(LogCategory, $"'{path}': {reason}");
            _events.Publish(new SceneLoadFailedEvent(path, reason));
            _tracker.Reset();
            return;
        }

        _logger.Info(LogCategory, $"Szene aktiviert: '{path}'.");
        _events.Publish(new SceneLoadCompletedEvent(path));
        _tracker.Reset();
    }

    private static SceneLoadStatus MapStatus(ResourceLoader.ThreadLoadStatus status) => status switch
    {
        ResourceLoader.ThreadLoadStatus.InProgress => SceneLoadStatus.InProgress,
        ResourceLoader.ThreadLoadStatus.Loaded => SceneLoadStatus.Loaded,
        ResourceLoader.ThreadLoadStatus.Failed => SceneLoadStatus.Failed,
        _ => SceneLoadStatus.InvalidResource,
    };
}
