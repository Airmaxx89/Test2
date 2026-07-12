using System.Numerics;

namespace Aethermoor.Gameplay.Input;

/// <summary>
/// Engine-unabhängige Quelle für Bewegungseingaben. Entkoppelt Konsumenten (Charakter-
/// Controller) von der konkreten Eingabemethode — virtueller Joystick, später optional ein
/// Gamepad —, sodass beide gegen denselben Vertrag arbeiten (Dependency-Inversion).
/// </summary>
/// <remarks>
/// Der Vektor ist normalisiert (Länge 0..1) in Bildschirmkonvention: <c>+X</c> nach rechts,
/// <c>+Y</c> nach unten. Bewusst <see cref="Vector2"/> aus <c>System.Numerics</c> (Godot-frei),
/// damit Controller-Logik ohne Engine testbar bleibt (siehe ARCHITECTURE §8).
/// </remarks>
public interface IMovementInputSource
{
    /// <summary>Aktueller, normalisierter Bewegungsvektor (Länge 0..1).</summary>
    Vector2 MovementVector { get; }
}
