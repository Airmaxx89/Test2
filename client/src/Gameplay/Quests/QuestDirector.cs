using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Enemies;
using Godot;

namespace Aethermoor.Gameplay.Quests;

/// <summary>
/// Führt die aktive Quest einer Zone: lädt die Daten, startet den getesteten
/// <see cref="QuestTracker"/>, zählt Gegner-Tode über den EventBus
/// (<see cref="EnemyDefeatedEvent"/> — entkoppelt von den dynamisch gespawnten Knoten)
/// und meldet Fortschritt als <see cref="QuestProgressEvent"/> an das HUD.
/// </summary>
/// <remarks>
/// Bewusst eine Quest pro Zone in dieser Vertikale; das vollwertige Questlog (mehrere
/// aktive Quests, Annahme/Abgabe bei NPCs) ist ein späterer Milestone (GAME_DESIGN §9).
/// </remarks>
public sealed partial class QuestDirector : Node
{
    private const string LogCategory = "Quests";

    /// <summary>Ressourcenpfad der Quest (<c>res://…tres</c>).</summary>
    [Export] public string QuestPath { get; set; } = string.Empty;

    private GameBootstrap _game = null!;
    private QuestTracker? _tracker;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");

        if (ResourceLoader.Load<QuestResource>(QuestPath) is not QuestResource resource)
        {
            _game.Logger.Error(LogCategory, $"Quest nicht ladbar: '{QuestPath}'.");
            return;
        }

        _tracker = new QuestTracker(resource.ToDefinition());
        _tracker.Start();
        _game.Events.Subscribe<EnemyDefeatedEvent>(OnEnemyDefeated);
        _game.Logger.Info(LogCategory, $"Quest angenommen: {_tracker.Definition.Title}.");

        // Erstanzeige verzögert veröffentlichen, damit auch später initialisierte
        // HUD-Knoten (Szenenbaum-Reihenfolge) die Meldung erhalten.
        Callable.From(PublishProgress).CallDeferred();
    }

    public override void _ExitTree()
    {
        if (_tracker is not null)
        {
            _game.Events.Unsubscribe<EnemyDefeatedEvent>(OnEnemyDefeated);
        }
    }

    private void OnEnemyDefeated(EnemyDefeatedEvent defeatedEvent)
    {
        if (_tracker is null || !_tracker.RegisterKill(defeatedEvent.EnemyId))
        {
            return;
        }

        PublishProgress();
        if (_tracker.State == QuestState.Completed)
        {
            _game.Logger.Info(LogCategory, $"Quest abgeschlossen: {_tracker.Definition.Title}.");
            _game.Events.Publish(new QuestCompletedEvent(
                _tracker.Definition.Id, _tracker.Definition.XpReward));
        }
    }

    private void PublishProgress()
    {
        if (_tracker is null)
        {
            return;
        }

        _game.Events.Publish(new QuestProgressEvent(
            _tracker.Definition.Title,
            _tracker.CurrentCount,
            _tracker.Definition.RequiredCount,
            _tracker.State == QuestState.Completed));
    }
}
