using System;
using System.Collections.Generic;
using Aethermoor.Core.Bootstrap;
using Aethermoor.Gameplay.Abilities;
using Godot;

namespace Aethermoor.UI.Controls;

/// <summary>
/// Touch-Zauberleiste: ordnet <see cref="AbilityButton"/>s als Bogen in der rechten
/// Daumenzone an (GAME_DESIGN §13 — bequem mit dem Daumen erreichbar, links bleibt der
/// Joystick). Lädt Fähigkeiten als Daten (<see cref="AbilityResource"/>-Pfade), besitzt den
/// <see cref="AbilityCaster"/> und speist die Buttons pro Frame mit dem Zustand aus dem
/// getesteten <see cref="AbilityStatusResolver"/>.
/// </summary>
/// <remarks>
/// Wirkversuche laufen ausschließlich durch <see cref="AbilityCaster.TryCast"/>; Ergebnis
/// wird als <see cref="AbilityCastPredictedEvent"/>/<see cref="AbilityCastRejectedEvent"/>
/// über den EventBus gemeldet (Audio/VFX/Fehlertext docken dort an). Die Zielprüfung nutzt
/// vorerst Distanz 0 — die Smart-Targeting-Anbindung folgt mit dem Gegner-Milestone.
/// </remarks>
public sealed partial class AbilityBar : Control
{
    private const string LogCategory = "Abilities";
    private const int MaxSlots = 6;
    private const float ButtonSize = 96f;
    private const float ArcRadius = 175f;
    private const float FirstSlotAngleDegrees = 95f;
    private const float SlotAngleStepDegrees = 24f;

    /// <summary>Ressourcenpfade der Fähigkeiten (<c>res://…tres</c>), Reihenfolge = Slots.</summary>
    [Export] public string[] AbilityPaths { get; set; } = Array.Empty<string>();

    /// <summary>Maximale Ressource des Charakters (Platzhalter bis zum Attributsystem).</summary>
    [Export(PropertyHint.Range, "1,1000,1")] public float MaxResource { get; set; } = 100f;

    /// <summary>Ressourcen-Regeneration pro Sekunde.</summary>
    [Export(PropertyHint.Range, "0,100,0.5")] public float ResourceRegenPerSecond { get; set; } = 5f;

    private readonly List<AbilityButton> _buttons = new();
    private GameBootstrap _game = null!;
    private AbilityCaster? _caster;

    public override void _Ready()
    {
        _game = GetNode<GameBootstrap>("/root/Game");
        MouseFilter = MouseFilterEnum.Ignore; // nur die Buttons fangen Berührungen

        List<AbilityDefinition> definitions = LoadDefinitions();
        if (definitions.Count == 0)
        {
            _game.Logger.Warning(LogCategory, "Zauberleiste ohne Fähigkeiten — keine Buttons erzeugt.");
            return;
        }

        _caster = new AbilityCaster(definitions, MaxResource);
        BuildButtons(definitions);
    }

    public override void _Process(double delta)
    {
        if (_caster is null)
        {
            return;
        }

        _caster.RestoreResource(ResourceRegenPerSecond * (float)delta);

        double now = NowSeconds();
        int index = 0;
        foreach (AbilityDefinition definition in _caster.Abilities)
        {
            if (index >= _buttons.Count)
            {
                break;
            }

            _buttons[index].UpdateStatus(AbilityStatusResolver.Resolve(_caster, definition, now));
            index++;
        }
    }

    private void OnCastRequested(string abilityId)
    {
        if (_caster is null)
        {
            return;
        }

        // Distanz 0: noch keine Ziele — Smart-Targeting-Anbindung folgt mit dem Gegner-Milestone.
        if (_caster.TryCast(abilityId, NowSeconds(), distanceToTarget: 0f, out CastFailureReason reason))
        {
            _game.Logger.Debug(LogCategory, $"Gewirkt (prädiktiv): {abilityId}.");
            _game.Events.Publish(new AbilityCastPredictedEvent(abilityId));
        }
        else
        {
            _game.Logger.Debug(LogCategory, $"Abgelehnt: {abilityId} ({reason}).");
            _game.Events.Publish(new AbilityCastRejectedEvent(abilityId, reason));
        }
    }

    private List<AbilityDefinition> LoadDefinitions()
    {
        var definitions = new List<AbilityDefinition>();
        foreach (string path in AbilityPaths)
        {
            if (definitions.Count >= MaxSlots)
            {
                _game.Logger.Warning(LogCategory, $"Mehr als {MaxSlots} Fähigkeiten — Rest ignoriert.");
                break;
            }

            if (ResourceLoader.Load<AbilityResource>(path) is AbilityResource resource)
            {
                definitions.Add(resource.ToDefinition());
            }
            else
            {
                _game.Logger.Error(LogCategory, $"Fähigkeit nicht ladbar: '{path}'.");
            }
        }

        return definitions;
    }

    private void BuildButtons(List<AbilityDefinition> definitions)
    {
        // Bogen um die untere rechte Ecke der Leiste (Daumen-Reichweite).
        Vector2 corner = Size;
        for (int i = 0; i < definitions.Count; i++)
        {
            float angleRadians = Mathf.DegToRad(FirstSlotAngleDegrees + (SlotAngleStepDegrees * i));
            Vector2 center = corner + new Vector2(
                Mathf.Cos(angleRadians) * ArcRadius,
                -Mathf.Sin(angleRadians) * ArcRadius);

            var button = new AbilityButton
            {
                Position = center - (new Vector2(ButtonSize, ButtonSize) / 2f),
                Size = new Vector2(ButtonSize, ButtonSize),
                MouseFilter = MouseFilterEnum.Stop,
            };
            button.Bind(definitions[i]);
            button.CastRequested += OnCastRequested;

            AddChild(button);
            _buttons.Add(button);
        }
    }

    private static double NowSeconds() => Time.GetTicksMsec() / 1000.0;
}
