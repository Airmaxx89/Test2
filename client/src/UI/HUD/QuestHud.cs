using System.Globalization;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Quests;
using Godot;

namespace Aethermoor.UI.HUD;

/// <summary>
/// Kompakte Quest-Anzeige (rechts oben): Titel + Fortschritt, grün bei Abschluss.
/// Rein event-getrieben über <see cref="QuestProgressEvent"/> — kennt weder Quest- noch
/// Gegner-Knoten (Vorläufer des vollwertigen Questlogs, GAME_DESIGN §13).
/// </summary>
public sealed partial class QuestHud : Control
{
    private static readonly Color BackColor = new(0f, 0f, 0f, 0.45f);
    private static readonly Color TextColor = new(1f, 1f, 1f, 0.95f);
    private static readonly Color CompletedColor = new(0.35f, 0.95f, 0.40f);

    private GameBootstrap _game = null!;
    private string _title = string.Empty;
    private int _current;
    private int _required;
    private bool _completed;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        _game.Events.Subscribe<QuestProgressEvent>(OnQuestProgress);
        Visible = false; // erst zeigen, wenn eine Quest gemeldet wird
    }

    public override void _ExitTree()
    {
        _game.Events.Unsubscribe<QuestProgressEvent>(OnQuestProgress);
    }

    private void OnQuestProgress(QuestProgressEvent progress)
    {
        _title = progress.Title;
        _current = progress.Current;
        _required = progress.Required;
        _completed = progress.Completed;
        Visible = true;
        QueueRedraw();
    }

    public override void _Draw()
    {
        DrawRect(new Rect2(Vector2.Zero, Size), BackColor);

        Font font = GetThemeDefaultFont();
        int fontSize = GetThemeDefaultFontSize();

        string progress = _completed
            ? "Abgeschlossen!"
            : string.Create(CultureInfo.InvariantCulture, $"{_current} / {_required}");

        DrawString(font, new Vector2(10f, fontSize + 8f), _title,
            HorizontalAlignment.Left, Size.X - 20f, fontSize, TextColor);
        DrawString(font, new Vector2(10f, (fontSize * 2) + 16f), progress,
            HorizontalAlignment.Left, Size.X - 20f, fontSize,
            _completed ? CompletedColor : TextColor);
    }
}
