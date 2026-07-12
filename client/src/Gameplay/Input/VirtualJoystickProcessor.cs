using System;
using System.Numerics;

namespace Aethermoor.Gameplay.Input;

/// <summary>
/// Engine-freie Auswertung eines virtuellen Joysticks: übersetzt Basismittelpunkt und
/// aktuelle Berührungsposition in Richtung, normalisierte Stärke und geklemmten Griffversatz.
/// </summary>
/// <remarks>
/// <para>
/// Bewusst Godot-frei (nur <c>System.Numerics</c>), damit die gesamte Fühl-Charakteristik —
/// Totzone gegen Zittern, radiale Klemmung, lineare Remap der Stärke — in CI unit-getestet
/// werden kann (siehe ARCHITECTURE §8). Der Godot-Control <c>VirtualJoystick</c> reicht nur
/// Berührungspunkte hinein und zeichnet das Ergebnis.
/// </para>
/// <para>
/// Die Stärke wird von der Totzonengrenze (0) bis zum Radius (1) linear neu abgebildet, damit
/// direkt hinter der Totzone kein Sprung entsteht und die volle Feinsteuerung erhalten bleibt.
/// </para>
/// </remarks>
public sealed class VirtualJoystickProcessor
{
    private readonly float _radius;
    private readonly float _deadZoneRatio;

    /// <param name="radius">Maximale Auslenkung in Pixeln (&gt; 0).</param>
    /// <param name="deadZoneRatio">Totzone als Anteil des Radius, im Bereich [0, 1).</param>
    /// <exception cref="ArgumentOutOfRangeException">
    /// Wenn <paramref name="radius"/> ≤ 0 oder <paramref name="deadZoneRatio"/> außerhalb [0, 1) liegt.
    /// </exception>
    public VirtualJoystickProcessor(float radius, float deadZoneRatio)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(radius);
        if (deadZoneRatio < 0f || deadZoneRatio >= 1f)
        {
            throw new ArgumentOutOfRangeException(
                nameof(deadZoneRatio), deadZoneRatio, "Totzone muss im Bereich [0, 1) liegen.");
        }

        _radius = radius;
        _deadZoneRatio = deadZoneRatio;
    }

    /// <summary>Wertet eine Berührung relativ zur Basis aus.</summary>
    /// <param name="baseCenter">Mittelpunkt der Joystick-Basis (Bildschirmkoordinaten).</param>
    /// <param name="touchPosition">Aktuelle Position des Fingers (Bildschirmkoordinaten).</param>
    public JoystickOutput Compute(Vector2 baseCenter, Vector2 touchPosition)
    {
        Vector2 delta = touchPosition - baseCenter;
        float distance = delta.Length();

        // Exakt zentriert: keine definierte Richtung -> neutral.
        if (distance <= float.Epsilon)
        {
            return JoystickOutput.Inactive;
        }

        Vector2 direction = delta / distance;                    // Einheitsvektor
        float clampedDistance = MathF.Min(distance, _radius);    // Griff bleibt im Radius
        Vector2 handleOffset = direction * clampedDistance;

        float deadZonePixels = _deadZoneRatio * _radius;
        if (clampedDistance <= deadZonePixels)
        {
            // Innerhalb der Totzone: keine Bewegung, Griff folgt aber sichtbar dem Finger.
            return new JoystickOutput(Vector2.Zero, 0f, handleOffset);
        }

        float magnitude = (clampedDistance - deadZonePixels) / (_radius - deadZonePixels);
        magnitude = Math.Clamp(magnitude, 0f, 1f);
        return new JoystickOutput(direction, magnitude, handleOffset);
    }
}
