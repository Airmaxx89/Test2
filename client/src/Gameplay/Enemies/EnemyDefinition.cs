namespace Aethermoor.Gameplay.Enemies;

/// <summary>
/// Engine-freie Datenbeschreibung eines Gegnertyps (ARCHITECTURE §4: ein neuer Gegner ist
/// eine neue <c>EnemyResource</c>-Datei, kein Codeeingriff). Verhaltensparameter der
/// KI-Zustandsmaschine (<see cref="EnemyBrain"/>) inklusive.
/// </summary>
/// <param name="Id">Eindeutige, stabile Kennung (z. B. <c>"silberwald.wegelagerer"</c>).</param>
/// <param name="DisplayName">Anzeigename (Nameplate, Kampflog).</param>
/// <param name="MaxHealth">Maximales Leben (&gt; 0).</param>
/// <param name="MoveSpeed">Bewegungstempo in px/s.</param>
/// <param name="AggroRadius">Radius, in dem Spieler Aggro auslösen.</param>
/// <param name="LeashRadius">
/// Maximale Entfernung vom Heimatpunkt; darüber bricht die Verfolgung ab und der Gegner
/// kehrt heim (Anti-Kiting, GAME_DESIGN §8).
/// </param>
/// <param name="AttackRange">Reichweite, ab der angegriffen statt verfolgt wird.</param>
public sealed record EnemyDefinition(
    string Id,
    string DisplayName,
    float MaxHealth,
    float MoveSpeed,
    float AggroRadius,
    float LeashRadius,
    float AttackRange);
