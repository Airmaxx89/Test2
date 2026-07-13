namespace Aethermoor.Gameplay.Quests;

/// <summary>
/// Engine-freie Beschreibung einer Tötungs-Quest (Startumfang der Vertikale; weitere
/// Zieltypen — sammeln, eskortieren, interagieren — folgen als eigene Definitionen,
/// GAME_DESIGN §9). Eine neue Quest ist eine neue <c>QuestResource</c>-Datei.
/// </summary>
/// <param name="Id">Eindeutige, stabile Kennung (z. B. <c>"morgenau.wegelagerer_plage"</c>).</param>
/// <param name="Title">Titel für Questlog/HUD.</param>
/// <param name="TargetEnemyId">Gegner-Kennung, deren Tode zählen (<c>EnemyDefinition.Id</c>).</param>
/// <param name="RequiredCount">Benötigte Anzahl (&gt; 0).</param>
/// <param name="XpReward">Erfahrung bei Abschluss.</param>
public sealed record QuestDefinition(
    string Id,
    string Title,
    string TargetEnemyId,
    int RequiredCount,
    float XpReward = 0f);
