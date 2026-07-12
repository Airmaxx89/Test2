using System;
using System.Globalization;
using Aethermoor.Gameplay.Abilities;
using Godot;

namespace Aethermoor.UI.Controls;

/// <summary>
/// Runder Touch-Button für eine Fähigkeit: große Touchfläche (GAME_DESIGN §13), radiale
/// Cooldown-Anzeige und Ausgrau-Zustand bei fehlender Ressource. Zeichnet sich selbst
/// (<see cref="CanvasItem._Draw"/>), bis echte Icon-Assets kommen.
/// </summary>
/// <remarks>
/// Reine Darstellung + Toucherkennung: Zustand kommt pro Frame von der
/// <see cref="AbilityBar"/> über <see cref="UpdateStatus"/> (abgeleitet vom getesteten
/// <see cref="AbilityStatusResolver"/>); ob gewirkt werden darf, entscheidet der
/// <see cref="AbilityCaster"/>, nie der Button.
/// </remarks>
public sealed partial class AbilityButton : Control
{
    /// <summary>Signal: Der Spieler hat den Button gedrückt (Wirkwunsch).</summary>
    [Signal]
    public delegate void CastRequestedEventHandler(string abilityId);

    private static readonly Color ReadyColor = new(0.20f, 0.45f, 0.80f, 0.90f);
    private static readonly Color UnaffordableColor = new(0.25f, 0.30f, 0.40f, 0.75f);
    private static readonly Color CooldownColor = new(0.15f, 0.17f, 0.22f, 0.85f);
    private static readonly Color ArcColor = new(1f, 1f, 1f, 0.85f);
    private static readonly Color TextColor = new(1f, 1f, 1f, 0.95f);

    private AbilityDefinition? _definition;
    private AbilityStatus _status;

    /// <summary>Bindet den Button an eine Fähigkeit (einmalig beim Aufbau der Leiste).</summary>
    public void Bind(AbilityDefinition definition)
    {
        ArgumentNullException.ThrowIfNull(definition);
        _definition = definition;
        TooltipText = definition.DisplayName;
        QueueRedraw();
    }

    /// <summary>Aktualisiert den Anzeige-Zustand (von der Leiste pro Frame aufgerufen).</summary>
    public void UpdateStatus(AbilityStatus status)
    {
        if (_status == status)
        {
            return;
        }

        _status = status;
        QueueRedraw();
    }

    public override void _GuiInput(InputEvent @event)
    {
        if (_definition is null)
        {
            return;
        }

        if (@event is InputEventScreenTouch { Pressed: true })
        {
            EmitSignal(SignalName.CastRequested, _definition.Id);
            AcceptEvent();
        }
    }

    public override void _Draw()
    {
        if (_definition is null)
        {
            return;
        }

        Vector2 center = Size / 2f;
        float radius = Math.Min(Size.X, Size.Y) / 2f;

        Color baseColor = _status.Readiness switch
        {
            AbilityReadiness.OnCooldown => CooldownColor,
            AbilityReadiness.Unaffordable => UnaffordableColor,
            _ => ReadyColor,
        };
        DrawCircle(center, radius, baseColor);

        string label;
        if (_status.Readiness == AbilityReadiness.OnCooldown)
        {
            // Radiale Rest-Anzeige: Bogen schrumpft, Zahl zählt herunter.
            float sweep = _status.CooldownFraction * Mathf.Tau;
            DrawArc(center, radius - 6f, -Mathf.Pi / 2f, (-Mathf.Pi / 2f) + sweep, 48, ArcColor, 5f);
            label = Math.Ceiling(_status.CooldownRemainingSeconds)
                .ToString(CultureInfo.InvariantCulture);
        }
        else
        {
            label = _definition.DisplayName.Length > 0
                ? _definition.DisplayName[..1]
                : "?";
        }

        Font font = GetThemeDefaultFont();
        int fontSize = GetThemeDefaultFontSize() + 6;
        DrawString(
            font,
            new Vector2(0f, center.Y + (fontSize / 2f)),
            label,
            HorizontalAlignment.Center,
            Size.X,
            fontSize,
            TextColor);
    }
}
