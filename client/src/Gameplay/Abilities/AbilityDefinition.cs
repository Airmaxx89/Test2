namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Engine-freie, unveränderliche Beschreibung einer Fähigkeit — die Datengrundlage des
/// Kampfsystems (ARCHITECTURE §4: Inhalte sind Daten, kein Code). Im Editor werden
/// Fähigkeiten als <c>AbilityResource</c> (.tres) gepflegt und in diesen Typ übersetzt,
/// damit die Kampflogik ohne Godot testbar bleibt.
/// </summary>
/// <param name="Id">Eindeutige, stabile Kennung (z. B. <c>"waechter.schildschlag"</c>).</param>
/// <param name="DisplayName">Anzeigename für UI/Tooltips.</param>
/// <param name="CooldownSeconds">Abklingzeit in Sekunden (≥ 0).</param>
/// <param name="ResourceCost">Ressourcenkosten (Mana/Wut/Energie, ≥ 0).</param>
/// <param name="Range">
/// Maximale Wirkreichweite in Weltpixeln. Werte ≤ 0 bedeuten „ohne Zielprüfung"
/// (Selbstwirkung/ungezielt).
/// </param>
/// <param name="EffectType">Grundwirkung der Fähigkeit.</param>
/// <param name="Magnitude">Wirkstärke (Schadens-/Heilbasiswert, ≥ 0).</param>
/// <param name="AppliesMarker">
/// Combo-Marker, den ein Treffer auf dem Ziel setzt (leer = keiner). Siehe GAME_DESIGN §7.
/// </param>
/// <param name="MarkerDurationSeconds">
/// Gültigkeitsdauer des gesetzten Markers in Sekunden (&gt; 0, wenn <paramref name="AppliesMarker"/>
/// gesetzt ist).
/// </param>
/// <param name="ConsumesMarker">
/// Combo-Marker, den diese Fähigkeit als Finisher verbraucht (leer = keiner).
/// </param>
/// <param name="ComboBonusMultiplier">
/// Wirkstärke-Multiplikator, wenn der verbrauchte Marker aktiv war (z. B. 1,6 = +60 %).
/// </param>
/// <remarks>
/// <b>Autorität:</b> Diese Werte dienen clientseitig der Vorhersage und UI (Buttons ausgrauen,
/// Tooltips). Verbindlich validiert und aufgelöst wird jede Ausführung serverseitig
/// (ADR-0002); die serverseitigen Definitionen sind die Wahrheit fürs Balancing.
/// </remarks>
public sealed record AbilityDefinition(
    string Id,
    string DisplayName,
    float CooldownSeconds,
    float ResourceCost,
    float Range,
    AbilityEffectType EffectType,
    float Magnitude,
    string AppliesMarker = "",
    float MarkerDurationSeconds = 0f,
    string ConsumesMarker = "",
    float ComboBonusMultiplier = 1f);
