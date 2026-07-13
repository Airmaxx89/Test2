using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Combat;
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

    /// <summary>Maximales Leben (Platzhalter bis zum Attributsystem).</summary>
    [Export(PropertyHint.Range, "1,10000,10")] public float MaxHealth { get; set; } = 200f;

    private readonly AutoRunController _autoRun = new();
    private GameBootstrap _game = null!;
    private IMovementInputSource? _input;
    private NumericsVector2 _lastFacing;
    private Vector2 _spawnPosition;

    /// <summary>Letzte Blickrichtung (Einheitsvektor) — Grundlage für Smart-Targeting-Kegel.</summary>
    public NumericsVector2 Facing => _lastFacing;

    /// <summary>Ob Auto-Laufen aktuell aktiv ist (für UI-Zustandsanzeige).</summary>
    public bool IsAutoRunning => _autoRun.IsActive;

    /// <summary>Lebenspunkte des Spielers (Regeln im engine-freien <see cref="HealthPool"/>).</summary>
    public HealthPool Health { get; private set; } = null!;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _spawnPosition = GlobalPosition;
        Health = new HealthPool(MaxHealth);

        _input = GetNodeOrNull(InputSourcePath) as IMovementInputSource;
        if (_input is null)
        {
            _game.Logger.Warning(
                LogCategory,
                $"Keine Eingabequelle unter '{InputSourcePath}' gefunden — Charakter bleibt stehen.");
        }
    }

    /// <summary>
    /// Fügt dem Spieler Schaden zu (von Gegnern gerufen). Bei 0 Leben: Tod-Ereignis und
    /// Playground-Respawn am Startpunkt mit vollem Leben.
    /// </summary>
    public void ApplyDamage(float amount)
    {
        float applied = Health.ApplyDamage(amount);
        if (applied <= 0f)
        {
            return;
        }

        var position = new NumericsVector2(GlobalPosition.X, GlobalPosition.Y);
        _game.Events.Publish(new CombatNumberEvent(position, applied, CombatNumberKind.DamageTaken));
        _game.Events.Publish(new PlayerHealthChangedEvent(Health.Current, Health.Max));

        if (Health.IsDead)
        {
            _game.Events.Publish(new PlayerDiedEvent());
            Respawn();
        }
    }

    /// <summary>Heilt den Spieler (z. B. „Zweiter Wind").</summary>
    public void Heal(float amount)
    {
        float applied = Health.Heal(amount);
        if (applied <= 0f)
        {
            return;
        }

        var position = new NumericsVector2(GlobalPosition.X, GlobalPosition.Y);
        _game.Events.Publish(new CombatNumberEvent(position, applied, CombatNumberKind.Heal));
        _game.Events.Publish(new PlayerHealthChangedEvent(Health.Current, Health.Max));
    }

    private void Respawn()
    {
        // Playground-Verhalten: sofortiger Respawn am Startpunkt. Der echte Sterbe-/
        // Wiederbelebungsfluss (Geistlauf, Friedhof) ist ein späteres Feature.
        _game.Logger.Info(LogCategory, "Spieler besiegt — Respawn am Startpunkt.");
        GlobalPosition = _spawnPosition;
        Health = new HealthPool(MaxHealth);
        _autoRun.Cancel();
        _game.Events.Publish(new PlayerHealthChangedEvent(Health.Current, Health.Max));
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
