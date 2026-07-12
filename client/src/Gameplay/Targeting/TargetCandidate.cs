using System.Numerics;

namespace Aethermoor.Gameplay.Targeting;

/// <summary>
/// Engine-freie Beschreibung eines möglichen Ziels für die Zielauswahl. Der Godot-Layer
/// erzeugt diese Momentaufnahmen aus den tatsächlichen Gegner-/NPC-Knoten und reicht sie an
/// den <see cref="SmartTargetSelector"/>.
/// </summary>
/// <param name="Id">Stabile Kennung des Ziels (z. B. Netzwerk-Entitäts-ID).</param>
/// <param name="Position">Weltposition des Ziels.</param>
/// <param name="IsTargetable">
/// Ob das Ziel aktuell anvisierbar ist (lebt, feindlich/neutral, nicht unverwundbar).
/// </param>
public readonly record struct TargetCandidate(long Id, Vector2 Position, bool IsTargetable);
