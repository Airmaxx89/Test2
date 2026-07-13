using Aethermoor.Core.Bootstrap;
using Aethermoor.Core.Pooling;
using Aethermoor.Gameplay.Combat;
using Godot;

namespace Aethermoor.UI.HUD;

/// <summary>
/// Zeigt Kampfzahlen (<see cref="CombatNumberEvent"/>) als schwebende, ausblendende Zahlen
/// in Weltkoordinaten an. Nutzt den <see cref="ObjectPool{T}"/> aus dem Kern: Im Kampf
/// werden keine Knoten erzeugt/zerstört, sondern wiederverwendet (ARCHITECTURE §6).
/// </summary>
public sealed partial class DamageNumberSpawner : Node2D
{
    private const int PrewarmCount = 8;
    private const int MaxPooled = 32;
    private const float SpawnHeightOffset = 34f;

    private static readonly Color DealtColor = new(1f, 0.9f, 0.35f);
    private static readonly Color TakenColor = new(1f, 0.30f, 0.25f);
    private static readonly Color HealColor = new(0.35f, 0.95f, 0.40f);

    private GameBootstrap _game = null!;
    private ObjectPool<DamageNumber> _pool = null!;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _pool = new ObjectPool<DamageNumber>(CreateNumber, prewarm: PrewarmCount, maxSize: MaxPooled);
        _game.Events.Subscribe<CombatNumberEvent>(OnCombatNumber);
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<CombatNumberEvent>(OnCombatNumber);
    }

    private DamageNumber CreateNumber()
    {
        var number = new DamageNumber { Visible = false };
        number.SetProcess(false);
        // Lambda statt Methodengruppe: Die Factory läuft beim Prewarm bereits im
        // Pool-Konstruktor, wo _pool noch nicht zugewiesen ist.
        number.Expired += n => _pool.Return(n);
        AddChild(number);
        return number;
    }

    private void OnCombatNumber(CombatNumberEvent numberEvent)
    {
        DamageNumber number = _pool.Rent();
        number.Present(
            new Vector2(numberEvent.WorldPosition.X, numberEvent.WorldPosition.Y - SpawnHeightOffset),
            numberEvent.Amount,
            ColorFor(numberEvent.Kind));
    }

    private static Color ColorFor(CombatNumberKind kind) => kind switch
    {
        CombatNumberKind.DamageTaken => TakenColor,
        CombatNumberKind.Heal => HealColor,
        _ => DealtColor,
    };
}
