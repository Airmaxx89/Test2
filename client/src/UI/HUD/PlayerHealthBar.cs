using System.Globalization;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Character;
using Aethermoor.Gameplay.Combat;
using Godot;

namespace Aethermoor.UI.HUD;

/// <summary>
/// HUD-Lebensbalken des Spielers (oben links, GAME_DESIGN §13). Aktualisiert sich über
/// <see cref="PlayerHealthChangedEvent"/> — kein Polling, keine Kopplung an den Charakter
/// außer der einmaligen Startwert-Abfrage.
/// </summary>
public sealed partial class PlayerHealthBar : Control
{
    private static readonly Color BackColor = new(0f, 0f, 0f, 0.55f);
    private static readonly Color FillColor = new(0.30f, 0.85f, 0.35f);
    private static readonly Color LowFillColor = new(0.95f, 0.30f, 0.20f);
    private static readonly Color TextColor = new(1f, 1f, 1f, 0.95f);
    private const float LowHealthThreshold = 0.3f;

    /// <summary>Optionaler Pfad zum Spieler für den Startwert (danach rein event-getrieben).</summary>
    [Export] public NodePath PlayerPath { get; set; } = new();

    private GameBootstrap _game = null!;
    private float _current = 1f;
    private float _max = 1f;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _game.Events.Subscribe<PlayerHealthChangedEvent>(OnHealthChanged);

        if (GetNodeOrNull<LocalCharacterController>(PlayerPath) is { } player)
        {
            _current = player.Health.Current;
            _max = player.Health.Max;
        }
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<PlayerHealthChangedEvent>(OnHealthChanged);
    }

    private void OnHealthChanged(PlayerHealthChangedEvent healthEvent)
    {
        _current = healthEvent.Current;
        _max = healthEvent.Max;
        QueueRedraw();
    }

    public override void _Draw()
    {
        float fraction = _max > 0f ? _current / _max : 0f;

        DrawRect(new Rect2(Vector2.Zero, Size), BackColor);
        DrawRect(
            new Rect2(new Vector2(2f, 2f), new Vector2((Size.X - 4f) * fraction, Size.Y - 4f)),
            fraction <= LowHealthThreshold ? LowFillColor : FillColor);

        string text = string.Create(
            CultureInfo.InvariantCulture, $"{_current:F0} / {_max:F0}");
        Font font = GetThemeDefaultFont();
        int fontSize = GetThemeDefaultFontSize();
        DrawString(
            font,
            new Vector2(0f, (Size.Y / 2f) + (fontSize / 2f) - 2f),
            text,
            HorizontalAlignment.Center,
            Size.X,
            fontSize,
            TextColor);
    }
}
