using System;
using System.Globalization;
using Aethermoor.Core.Pooling;
using Godot;

namespace Aethermoor.UI.HUD;

/// <summary>
/// Eine schwebende Kampfzahl: steigt auf, blendet aus und meldet sich danach über
/// <see cref="Expired"/> zurück in den Pool. Poolbar (<see cref="IPoolable"/>), damit im
/// Kampf keine Knoten allokiert/zerstört werden (CODING_STANDARDS §7, ARCHITECTURE §6).
/// </summary>
public sealed partial class DamageNumber : Node2D, IPoolable
{
    private const float LifetimeSeconds = 0.9f;
    private const float RisePixelsPerSecond = 55f;
    private const int FontSizeOffset = 4;

    /// <summary>Wird beim Ablauf der Lebenszeit gefeuert — der Spawner gibt die Zahl in den Pool zurück.</summary>
    public event Action<DamageNumber>? Expired;

    private string _text = string.Empty;
    private Color _color = Colors.White;
    private double _elapsed;

    /// <summary>Richtet die Zahl für eine Anzeige ein (nach dem Entleihen aufzurufen).</summary>
    public void Present(Vector2 worldPosition, float amount, Color color)
    {
        GlobalPosition = worldPosition;
        _text = Math.Round(amount).ToString(CultureInfo.InvariantCulture);
        _color = color;
        QueueRedraw();
    }

    /// <inheritdoc />
    public void OnRent()
    {
        _elapsed = 0;
        Modulate = Colors.White;
        Visible = true;
        SetProcess(true);
    }

    /// <inheritdoc />
    public void OnReturn()
    {
        Visible = false;
        SetProcess(false);
    }

    public override void _Process(double delta)
    {
        _elapsed += delta;
        Position += new Vector2(0f, -RisePixelsPerSecond * (float)delta);

        float alpha = 1f - (float)(_elapsed / LifetimeSeconds);
        Modulate = new Color(1f, 1f, 1f, Math.Max(alpha, 0f));

        if (_elapsed >= LifetimeSeconds)
        {
            Expired?.Invoke(this);
        }
    }

    public override void _Draw()
    {
        // Node2D besitzt keine Theme-Schnittstelle — Fallback-Font der Engine verwenden.
        Font font = ThemeDB.FallbackFont;
        int fontSize = ThemeDB.FallbackFontSize + FontSizeOffset;
        DrawString(
            font,
            new Vector2(-40f, 0f),
            _text,
            HorizontalAlignment.Center,
            80f,
            fontSize,
            _color);
    }
}
