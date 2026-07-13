using Godot;

namespace Aethermoor.Gameplay.Quests;

/// <summary>
/// Godot-Datenschicht einer Tötungs-Quest: im Editor als <c>.tres</c> pflegbar
/// (siehe <c>client/assets/quests/</c>). Eine neue Quest ist eine neue Datei; die Logik
/// arbeitet ausschließlich mit <see cref="QuestDefinition"/>.
/// </summary>
[GlobalClass]
public partial class QuestResource : Resource
{
    /// <summary>Eindeutige Kennung (Konvention: <c>zone.quest</c>).</summary>
    [Export] public string Id { get; set; } = string.Empty;

    /// <summary>Titel für Questlog/HUD.</summary>
    [Export] public string Title { get; set; } = string.Empty;

    /// <summary>Gegner-Kennung, deren Tode zählen (<c>EnemyResource.Id</c>).</summary>
    [Export] public string TargetEnemyId { get; set; } = string.Empty;

    /// <summary>Benötigte Anzahl.</summary>
    [Export(PropertyHint.Range, "1,999,1")] public int RequiredCount { get; set; } = 1;

    /// <summary>Erfahrung bei Abschluss.</summary>
    [Export(PropertyHint.Range, "0,100000,10")] public float XpReward { get; set; }

    /// <summary>Übersetzt in die engine-freie Definition für die Quest-Logik.</summary>
    public QuestDefinition ToDefinition() => new(Id, Title, TargetEnemyId, RequiredCount, XpReward);
}
