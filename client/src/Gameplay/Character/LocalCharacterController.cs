using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Input;
using Godot;

namespace Aethermoor.Gameplay.Character;

/// <summary>
/// Lokaler Platzhalter-Charakter, der eine <see cref="IMovementInputSource"/> (den virtuellen
/// Joystick) in Bewegung umsetzt. Dient in Milestone 2 dazu, die Steuerung greifbar und
/// prüfbar zu machen; die serverautoritative Bewegung folgt mit dem Netzwerk-Milestone.
/// </summary>
/// <remarks>
/// Die Eingabequelle wird gegen das engine-freie Interface aufgelöst, nicht gegen den
/// konkreten Joystick — der Controller bliebe damit auch mit einer anderen Eingabemethode
/// (z. B. Gamepad) unverändert (Dependency-Inversion, siehe CODING_STANDARDS §1).
/// </remarks>
public sealed partial class LocalCharacterController : CharacterBody2D
{
    private const string LogCategory = "Input";

    /// <summary>Bewegungsgeschwindigkeit in Pixeln pro Sekunde (Platzhalterwert).</summary>
    [Export(PropertyHint.Range, "50,1000,10")] public float MoveSpeed { get; set; } = 320f;

    /// <summary>Pfad zum Knoten, der <see cref="IMovementInputSource"/> implementiert.</summary>
    [Export] public NodePath InputSourcePath { get; set; } = new();

    private IMovementInputSource? _input;

    public override void _Ready()
    {
        _input = GetNodeOrNull(InputSourcePath) as IMovementInputSource;
        if (_input is null)
        {
            GetNodeOrNull<GameBootstrap>("/root/Game")?.Logger.Warning(
                LogCategory,
                $"Keine Eingabequelle unter '{InputSourcePath}' gefunden — Charakter bleibt stehen.");
        }
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_input is null)
        {
            return;
        }

        System.Numerics.Vector2 move = _input.MovementVector;
        Velocity = new Vector2(move.X, move.Y) * MoveSpeed;
        MoveAndSlide();
    }
}
