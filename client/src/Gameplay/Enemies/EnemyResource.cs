using Godot;

namespace Aethermoor.Gameplay.Enemies;

/// <summary>
/// Godot-Datenschicht eines Gegnertyps: im Editor als <c>.tres</c> pflegbar
/// (siehe <c>client/assets/enemies/</c>). Ein neuer Gegner ist eine neue Datei
/// (ARCHITECTURE §4); die Logik arbeitet ausschließlich mit <see cref="EnemyDefinition"/>.
/// </summary>
[GlobalClass]
public partial class EnemyResource : Resource
{
    /// <summary>Eindeutige Kennung (Konvention: <c>zone.gegner</c>).</summary>
    [Export] public string Id { get; set; } = string.Empty;

    /// <summary>Anzeigename.</summary>
    [Export] public string DisplayName { get; set; } = string.Empty;

    /// <summary>Maximales Leben.</summary>
    [Export(PropertyHint.Range, "1,100000,1")] public float MaxHealth { get; set; } = 100f;

    /// <summary>Bewegungstempo in px/s.</summary>
    [Export(PropertyHint.Range, "10,1000,10")] public float MoveSpeed { get; set; } = 160f;

    /// <summary>Aggro-Radius in px.</summary>
    [Export(PropertyHint.Range, "0,2000,10")] public float AggroRadius { get; set; } = 260f;

    /// <summary>Leinen-Radius (max. Distanz vom Heimatpunkt) in px.</summary>
    [Export(PropertyHint.Range, "0,5000,10")] public float LeashRadius { get; set; } = 600f;

    /// <summary>Angriffsreichweite in px.</summary>
    [Export(PropertyHint.Range, "0,2000,5")] public float AttackRange { get; set; } = 70f;

    /// <summary>Schaden pro Angriff.</summary>
    [Export(PropertyHint.Range, "0,10000,1")] public float AttackDamage { get; set; } = 10f;

    /// <summary>Mindestabstand zwischen zwei Angriffen in Sekunden.</summary>
    [Export(PropertyHint.Range, "0.2,30,0.1")] public float AttackIntervalSeconds { get; set; } = 1.5f;

    /// <summary>Erfahrung, die der Tod dieses Gegners gewährt.</summary>
    [Export(PropertyHint.Range, "0,100000,5")] public float XpReward { get; set; }

    /// <summary>Übersetzt in die engine-freie Definition für die KI-Logik.</summary>
    public EnemyDefinition ToDefinition()
        => new(Id, DisplayName, MaxHealth, MoveSpeed, AggroRadius, LeashRadius, AttackRange,
            AttackDamage, AttackIntervalSeconds, XpReward);
}
