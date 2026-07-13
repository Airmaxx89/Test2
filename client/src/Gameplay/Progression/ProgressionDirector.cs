using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Enemies;
using Aethermoor.Gameplay.Quests;
using Godot;

namespace Aethermoor.Gameplay.Progression;

/// <summary>
/// Führt die XP-/Level-Progression des Spielers: sammelt Erfahrungsquellen über den
/// EventBus (Gegner-Tode, Quest-Abschlüsse) in den getesteten
/// <see cref="ExperienceTracker"/> und meldet Stand und Level-Aufstiege zurück.
/// </summary>
/// <remarks>
/// Quellen kennen die Progression nicht — neue XP-Quellen (Berufe, Erkundung, Events)
/// publizieren einfach ihr Ereignis (Open/Closed). Persistenz und autoritative Vergabe
/// folgen mit dem Server-Milestone (ADR-0002).
/// </remarks>
public sealed partial class ProgressionDirector : Node
{
    private const string LogCategory = "Progression";

    private readonly ExperienceTracker _tracker = new();
    private GameBootstrap _game = null!;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _game.Events.Subscribe<EnemyDefeatedEvent>(OnEnemyDefeated);
        _game.Events.Subscribe<QuestCompletedEvent>(OnQuestCompleted);

        // Initialstand verzögert melden, damit auch später initialisierte HUD-Knoten ihn erhalten.
        Callable.From(() => PublishState(0f)).CallDeferred();
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<EnemyDefeatedEvent>(OnEnemyDefeated);
        _game.Events.Unsubscribe<QuestCompletedEvent>(OnQuestCompleted);
    }

    private void OnEnemyDefeated(EnemyDefeatedEvent defeated) => Grant(defeated.XpReward);

    private void OnQuestCompleted(QuestCompletedEvent completed) => Grant(completed.XpReward);

    private void Grant(float amount)
    {
        if (amount <= 0f)
        {
            return;
        }

        int levelUps = _tracker.GrantXp(amount);
        PublishState(amount);

        if (levelUps > 0)
        {
            _game.Logger.Info(LogCategory, $"Stufenaufstieg! Level {_tracker.Level}.");
            _game.Events.Publish(new LevelUpEvent(_tracker.Level));
        }
    }

    private void PublishState(float gainedAmount)
    {
        _game.Events.Publish(new ExperienceGainedEvent(
            gainedAmount,
            _tracker.Level,
            _tracker.CurrentXp,
            _tracker.XpToNextLevel,
            _tracker.ProgressFraction));
    }
}
