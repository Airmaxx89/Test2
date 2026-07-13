using System.Numerics;

namespace Aethermoor.Gameplay.Enemies;

/// <summary>
/// Ergebnis eines KI-Ticks: gewünschte Bewegung und Angriffsabsicht. Der Godot-Layer setzt
/// die Entscheidung in Bewegung/Animation um, das Gehirn bleibt engine-frei.
/// </summary>
/// <param name="State">Aktueller Zustand nach diesem Tick.</param>
/// <param name="MoveDirection">Normalisierte Bewegungsrichtung oder Nullvektor (stehen).</param>
/// <param name="WantsToAttack">Ob der Gegner in diesem Tick angreifen möchte.</param>
public readonly record struct EnemyAiDecision(
    EnemyAiState State,
    Vector2 MoveDirection,
    bool WantsToAttack);
