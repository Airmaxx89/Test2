using System.Numerics;

namespace Aethermoor.Gameplay.Input;

/// <summary>
/// Ergebnis einer Joystick-Auswertung durch den <see cref="VirtualJoystickProcessor"/>.
/// </summary>
/// <param name="Direction">
/// Normalisierte Bewegungsrichtung (Einheitsvektor) oder <see cref="Vector2.Zero"/>, wenn die
/// Auslenkung innerhalb der Totzone liegt.
/// </param>
/// <param name="Magnitude">
/// Normalisierte Stärke der Auslenkung im Bereich 0..1 (0 innerhalb der Totzone, 1 am Rand).
/// </param>
/// <param name="HandleOffset">
/// Versatz des Griffs relativ zur Basis, auf den Radius geklemmt — rein für die Darstellung.
/// Folgt dem Finger auch innerhalb der Totzone, damit der Griff sichtbar mitwandert.
/// </param>
public readonly record struct JoystickOutput(Vector2 Direction, float Magnitude, Vector2 HandleOffset)
{
    /// <summary>Neutrales Ergebnis: keine Richtung, keine Stärke, kein Versatz.</summary>
    public static JoystickOutput Inactive => new(Vector2.Zero, 0f, Vector2.Zero);
}
