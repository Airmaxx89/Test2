using Aethermoor.Core.Events;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.Gameplay.Combat;

/// <summary>Art einer Kampfzahl — bestimmt Farbe/Stil der Anzeige.</summary>
public enum CombatNumberKind
{
    /// <summary>Vom Spieler verursachter Schaden (hell).</summary>
    DamageDealt = 0,

    /// <summary>Vom Spieler erlittener Schaden (rot).</summary>
    DamageTaken = 1,

    /// <summary>Heilung (grün).</summary>
    Heal = 2,
}

/// <summary>
/// Fordert eine schwebende Kampfzahl an der Weltposition an. Entkoppelt Kampflogik von der
/// Darstellung: der gepoolte <c>DamageNumberSpawner</c> abonniert dieses Ereignis.
/// </summary>
public readonly record struct CombatNumberEvent(
    NumericsVector2 WorldPosition,
    float Amount,
    CombatNumberKind Kind) : IGameEvent;

/// <summary>Lebensstand des Spielers hat sich geändert (HUD-Lebensbalken).</summary>
public readonly record struct PlayerHealthChangedEvent(float Current, float Max) : IGameEvent;

/// <summary>Der Spieler ist gestorben (Respawn, Sterbe-UI, Statistik).</summary>
public readonly record struct PlayerDiedEvent : IGameEvent;
