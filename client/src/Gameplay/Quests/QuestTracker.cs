using System;

namespace Aethermoor.Gameplay.Quests;

/// <summary>
/// Engine-freier Fortschritts-Tracker einer Tötungs-Quest. Zählt passende Gegner-Tode und
/// wechselt beim Erreichen des Ziels in <see cref="QuestState.Completed"/>.
/// </summary>
/// <remarks>
/// Deterministisch und in CI getestet (ARCHITECTURE §8). Verbindlich wird Quest-Fortschritt
/// später serverseitig geführt (GAME_DESIGN §9); dieselbe Klasse ist dafür vorbereitet.
/// </remarks>
public sealed class QuestTracker
{
    /// <param name="definition">Quest-Daten (validiert: IDs nicht leer, Zielanzahl &gt; 0).</param>
    /// <exception cref="ArgumentNullException">Wenn <paramref name="definition"/> null ist.</exception>
    /// <exception cref="ArgumentException">Bei ungültigen Definitionswerten.</exception>
    public QuestTracker(QuestDefinition definition)
    {
        ArgumentNullException.ThrowIfNull(definition);
        if (string.IsNullOrWhiteSpace(definition.Id) || string.IsNullOrWhiteSpace(definition.TargetEnemyId))
        {
            throw new ArgumentException("Quest ohne gültige ID/Ziel-Kennung.", nameof(definition));
        }

        if (definition.RequiredCount <= 0)
        {
            throw new ArgumentException(
                $"Quest '{definition.Id}' benötigt eine positive Zielanzahl.", nameof(definition));
        }

        Definition = definition;
    }

    /// <summary>Die zugrunde liegende Quest-Definition.</summary>
    public QuestDefinition Definition { get; }

    /// <summary>Aktueller Zustand.</summary>
    public QuestState State { get; private set; } = QuestState.NotStarted;

    /// <summary>Bisher gezählte Tode des Zielgegners.</summary>
    public int CurrentCount { get; private set; }

    /// <summary>Nimmt die Quest an (nur aus <see cref="QuestState.NotStarted"/>).</summary>
    /// <exception cref="InvalidOperationException">Wenn bereits gestartet oder abgeschlossen.</exception>
    public void Start()
    {
        if (State != QuestState.NotStarted)
        {
            throw new InvalidOperationException($"Quest '{Definition.Id}' wurde bereits gestartet.");
        }

        State = QuestState.Active;
    }

    /// <summary>
    /// Meldet einen Gegner-Tod. Liefert <c>true</c>, wenn sich der Fortschritt geändert hat
    /// (zählt nur den Zielgegner, nur im Zustand <see cref="QuestState.Active"/>).
    /// </summary>
    public bool RegisterKill(string enemyId)
    {
        if (State != QuestState.Active || enemyId != Definition.TargetEnemyId)
        {
            return false;
        }

        CurrentCount++;
        if (CurrentCount >= Definition.RequiredCount)
        {
            State = QuestState.Completed;
        }

        return true;
    }
}
