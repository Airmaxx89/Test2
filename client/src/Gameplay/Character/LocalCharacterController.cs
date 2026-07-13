using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Input;
using Godot;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.Gameplay.Character;

/// <summary>
/// Lokaler Platzhalter-Charakter, der eine <see cref="IMovementInputSource"/> (den virtuellen
/// Joystick) in Bewegung umsetzt und Auto-Laufen unterstützt. Dient in Milestone 2 dazu, die
/// Steuerung greifbar und prüfbar zu machen; die serverautoritative Bewegung folgt mit dem
/// Netzwerk-Milestone.
/// </summary>
/// <remarks>
/// Eingabequelle und Auto-Lauf-Logik sind engine-frei abstrahiert (<see cref="AutoRunController"/>);
/// der Controller bliebe damit auch mit einer anderen Eingabemethode unverändert
/// (Dependency-Inversion, siehe CODING_STANDARDS §1).
/// </remarks>
public sealed partial class LocalCharacterController : CharacterBody2D
{
    private const string LogCategory = "Input";
    private const float MovingEpsilonSquared = 0.0001f;

    /// <summary>Bewegungsgeschwindigkeit in Pixeln pro Sekunde (Platzhalterwert).</summary>
    [Export(PropertyHint.Range, "50,1000,10")] public float MoveSpeed { get; set; } = 320f;

    /// <summary>Pfad zum Knoten, der <see cref="IMovementInputSource"/> implementiert.</summary>
    [Export] public NodePath InputSourcePath { get; set; } = new();

    private readonly AutoRunController _autoRun = new();
    private IMovementInputSource? _input;
    private NumericsVector2 _lastFacing;

    /// <summary>Letzte Blickrichtung (Einheitsvektor) — Grundlage für Smart-Targeting-Kegel.</summary>
    public NumericsVector2 Facing => _lastFacing;

    /// <summary>Ob Auto-Laufen aktuell aktiv ist (für UI-Zustandsanzeige).</summary>
    public bool IsAutoRunning => _autoRun.IsActive;

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

    /// <summary>Schaltet Auto-Laufen um (wird vom UI-Button aufgerufen).</summary>
    public void ToggleAutoRun()
    {
        NumericsVector2 live = _input?.MovementVector ?? NumericsVector2.Zero;
        _autoRun.Toggle(live, _lastFacing);
    }

    public override void _PhysicsProcess(double delta)
    {
        NumericsVector2 live = _input?.MovementVector ?? NumericsVector2.Zero;
        NumericsVector2 move = _autoRun.Resolve(live);

        if (move.LengthSquared() > MovingEpsilonSquared)
        {
            _lastFacing = NumericsVector2.Normalize(move);
        }

        Velocity = new Vector2(move.X, move.Y) * MoveSpeed;
        MoveAndSlide();
    }
}
