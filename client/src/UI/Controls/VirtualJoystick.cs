using Aethermoor.Gameplay.Input;
using Godot;
using NumericsVector2 = System.Numerics.Vector2;

namespace Aethermoor.UI.Controls;

/// <summary>
/// Touch-first virtueller Joystick. Erscheint dynamisch dort, wo der Daumen die
/// Aktivierungsfläche berührt (gute Ein-/Zweihand-Ergonomie, siehe GAME_DESIGN §13), und
/// stellt die Auslenkung als engine-freie <see cref="IMovementInputSource"/> bereit.
/// </summary>
/// <remarks>
/// <para>
/// Die gesamte Fühl-Logik liegt im getesteten <see cref="VirtualJoystickProcessor"/>; dieser
/// Control kümmert sich nur um Multi-Touch-Verwaltung und Darstellung. Er verfolgt genau
/// einen Finger (den ersten, der innerhalb der Fläche beginnt) und ignoriert weitere Finger,
/// damit der zweite Daumen parallel Fähigkeiten-Buttons bedienen kann.
/// </para>
/// <para>
/// Auf dem Desktop funktioniert die Bedienung dank <c>emulate_touch_from_mouse</c> identisch,
/// sodass sich der Fluss auch ohne Gerät testen lässt.
/// </para>
/// </remarks>
public sealed partial class VirtualJoystick : Control, IMovementInputSource
{
    private const int NoFinger = -1;

    /// <summary>Maximale Auslenkung des Griffs in Pixeln.</summary>
    [Export(PropertyHint.Range, "40,400,1")] public float Radius { get; set; } = 120f;

    /// <summary>Totzone als Anteil des Radius (dämpft Zittern nahe der Mitte).</summary>
    [Export(PropertyHint.Range, "0,0.9,0.01")] public float DeadZone { get; set; } = 0.15f;

    /// <summary>Farbe des Basisrings.</summary>
    [Export] public Color BaseColor { get; set; } = new(1f, 1f, 1f, 0.15f);

    /// <summary>Farbe des Griffs.</summary>
    [Export] public Color HandleColor { get; set; } = new(1f, 1f, 1f, 0.35f);

    private VirtualJoystickProcessor _processor = null!;
    private int _activeFinger = NoFinger;
    private Vector2 _baseCenter;
    private Vector2 _handleOffset;
    private NumericsVector2 _movement;

    /// <inheritdoc />
    public NumericsVector2 MovementVector => _movement;

    public override void _Ready()
    {
        _processor = new VirtualJoystickProcessor(Radius, DeadZone);
        MouseFilter = MouseFilterEnum.Stop;
    }

    public override void _GuiInput(InputEvent @event)
    {
        switch (@event)
        {
            case InputEventScreenTouch touch:
                HandleTouch(touch);
                break;
            case InputEventScreenDrag drag when drag.Index == _activeFinger:
                UpdateHandle(drag.Position);
                AcceptEvent();
                break;
        }
    }

    private void HandleTouch(InputEventScreenTouch touch)
    {
        if (touch.Pressed && _activeFinger == NoFinger)
        {
            _activeFinger = touch.Index;
            _baseCenter = touch.Position;
            UpdateHandle(touch.Position);
            AcceptEvent();
        }
        else if (!touch.Pressed && touch.Index == _activeFinger)
        {
            ResetStick();
            AcceptEvent();
        }
    }

    private void UpdateHandle(Vector2 touchPosition)
    {
        JoystickOutput output = _processor.Compute(
            new NumericsVector2(_baseCenter.X, _baseCenter.Y),
            new NumericsVector2(touchPosition.X, touchPosition.Y));

        _handleOffset = new Vector2(output.HandleOffset.X, output.HandleOffset.Y);
        _movement = output.Direction * output.Magnitude;
        QueueRedraw();
    }

    private void ResetStick()
    {
        _activeFinger = NoFinger;
        _handleOffset = Vector2.Zero;
        _movement = NumericsVector2.Zero;
        QueueRedraw();
    }

    public override void _Draw()
    {
        if (_activeFinger == NoFinger)
        {
            return;
        }

        DrawCircle(_baseCenter, Radius, BaseColor);
        DrawCircle(_baseCenter + _handleOffset, Radius * 0.4f, HandleColor);
    }
}
