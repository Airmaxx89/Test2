using System.Globalization;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Progression;
using Godot;

namespace Aethermoor.UI.HUD;

/// <summary>
/// XP-Leiste unter dem Lebensbalken: Level-Anzeige + Fortschrittsfüllung. Rein
/// event-getrieben über <see cref="ExperienceGainedEvent"/> — zustandslos gegenüber
/// der Progression (das Ereignis trägt den vollen Anzeigezustand).
/// </summary>
public sealed partial class XpBar : Control
{
    private static readonly Color BackColor = new(0f, 0f, 0f, 0.55f);
    private static readonly Color FillColor = new(0.55f, 0.40f, 0.90f);
    private static readonly Color TextColor = new(1f, 1f, 1f, 0.95f);

    private GameBootstrap _game = null!;
    private int _level = 1;
    private float _fraction;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _game.Events.Subscribe<ExperienceGainedEvent>(OnExperienceGained);
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<ExperienceGainedEvent>(OnExperienceGained);
    }

    private void OnExperienceGained(ExperienceGainedEvent xpEvent)
    {
        _level = xpEvent.Level;
        _fraction = xpEvent.ProgressFraction;
        QueueRedraw();
    }

    public override void _Draw()
    {
        DrawRect(new Rect2(Vector2.Zero, Size), BackColor);
        DrawRect(
            new Rect2(new Vector2(2f, 2f), new Vector2((Size.X - 4f) * _fraction, Size.Y - 4f)),
            FillColor);

        string text = string.Create(CultureInfo.InvariantCulture, $"Lv {_level}");
        Font font = GetThemeDefaultFont();
        int fontSize = GetThemeDefaultFontSize() - 2;
        DrawString(
            font,
            new Vector2(6f, (Size.Y / 2f) + (fontSize / 2f) - 1f),
            text,
            HorizontalAlignment.Left,
            Size.X - 12f,
            fontSize,
            TextColor);
    }
}
