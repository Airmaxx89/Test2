using Godot;

namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Godot-Datenschicht einer Fähigkeit: im Editor als <c>.tres</c> pflegbar
/// (siehe <c>client/assets/abilities/</c>). Eine neue Fähigkeit ist eine neue Datei —
/// kein Codeeingriff am Kampfsystem (ARCHITECTURE §4, Open/Closed).
/// </summary>
/// <remarks>
/// Reine Datenhülle: Die Logik arbeitet ausschließlich mit der engine-freien
/// <see cref="AbilityDefinition"/>, die <see cref="ToDefinition"/> liefert. Validiert wird
/// beim Aufbau des <see cref="AbilityCaster"/> — fehlerhafte Daten fallen beim Laden auf.
/// </remarks>
[GlobalClass]
public partial class AbilityResource : Resource
{
    /// <summary>Eindeutige, stabile Kennung (Konvention: <c>klasse.faehigkeit</c>).</summary>
    [Export] public string Id { get; set; } = string.Empty;

    /// <summary>Anzeigename für UI und Tooltips.</summary>
    [Export] public string DisplayName { get; set; } = string.Empty;

    /// <summary>Abklingzeit in Sekunden.</summary>
    [Export(PropertyHint.Range, "0,300,0.1")] public float CooldownSeconds { get; set; }

    /// <summary>Ressourcenkosten (Mana/Wut/Energie).</summary>
    [Export(PropertyHint.Range, "0,1000,1")] public float ResourceCost { get; set; }

    /// <summary>Wirkreichweite in Weltpixeln; ≤ 0 = ohne Zielprüfung.</summary>
    [Export(PropertyHint.Range, "0,2000,10")] public float Range { get; set; }

    /// <summary>Grundwirkung.</summary>
    [Export] public AbilityEffectType EffectType { get; set; } = AbilityEffectType.Damage;

    /// <summary>Wirkstärke (Basisschaden/-heilung).</summary>
    [Export(PropertyHint.Range, "0,10000,1")] public float Magnitude { get; set; }

    /// <summary>Übersetzt in die engine-freie Definition für die Kampflogik.</summary>
    public AbilityDefinition ToDefinition()
        => new(Id, DisplayName, CooldownSeconds, ResourceCost, Range, EffectType, Magnitude);
}
