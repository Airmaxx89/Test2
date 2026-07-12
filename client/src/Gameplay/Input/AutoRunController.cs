using System;
using System.Numerics;

namespace Aethermoor.Gameplay.Input;

/// <summary>
/// Engine-freie Zustandslogik für Auto-Laufen. Hält eine eingerastete Laufrichtung und
/// verrechnet sie mit der Live-Eingabe: Der Spieler kann während des Auto-Laufens weiter
/// lenken, und ein deutliches Gegensteuern bricht das Auto-Laufen ab — ein für Mobile
/// wichtiges Komfort-Feature (GAME_DESIGN §13), das eine Hand entlastet.
/// </summary>
/// <remarks>
/// Bewusst Godot-frei (nur <c>System.Numerics</c>) und damit in CI unit-testbar
/// (siehe ARCHITECTURE §8). Der Charakter-Controller besitzt eine Instanz und ruft
/// <see cref="Toggle"/> (per UI-Button) sowie pro Frame <see cref="Resolve"/> auf.
/// </remarks>
public sealed class AutoRunController
{
    private readonly float _inputThreshold;
    private readonly float _cancelDot;
    private Vector2 _latchedDirection;

    /// <param name="inputThreshold">
    /// Mindeststärke der Live-Eingabe (0..1), ab der gelenkt oder abgebrochen wird.
    /// </param>
    /// <param name="cancelDot">
    /// Skalarprodukt-Schwelle (-1..1): Liegt die Live-Richtung unter diesem Wert relativ zur
    /// Laufrichtung (also deutlich entgegengesetzt), wird das Auto-Laufen abgebrochen.
    /// </param>
    /// <exception cref="ArgumentOutOfRangeException">Bei Werten außerhalb der gültigen Bereiche.</exception>
    public AutoRunController(float inputThreshold = 0.2f, float cancelDot = -0.5f)
    {
        if (inputThreshold is < 0f or > 1f)
        {
            throw new ArgumentOutOfRangeException(
                nameof(inputThreshold), inputThreshold, "Schwelle muss in [0, 1] liegen.");
        }

        if (cancelDot is < -1f or > 1f)
        {
            throw new ArgumentOutOfRangeException(
                nameof(cancelDot), cancelDot, "Skalarprodukt-Schwelle muss in [-1, 1] liegen.");
        }

        _inputThreshold = inputThreshold;
        _cancelDot = cancelDot;
    }

    /// <summary>Ob Auto-Laufen aktiv ist.</summary>
    public bool IsActive { get; private set; }

    /// <summary>
    /// Schaltet Auto-Laufen um. Beim Aktivieren wird eine Laufrichtung eingerastet: bevorzugt
    /// aus der Live-Eingabe, sonst aus <paramref name="fallbackFacing"/> (z. B. Blickrichtung).
    /// Fehlt beides, bleibt Auto-Laufen inaktiv.
    /// </summary>
    public void Toggle(Vector2 liveInput, Vector2 fallbackFacing)
    {
        if (IsActive)
        {
            IsActive = false;
            return;
        }

        Vector2 source = liveInput.Length() >= _inputThreshold ? liveInput : fallbackFacing;
        if (source.Length() <= float.Epsilon)
        {
            return; // keine Richtung zum Einrasten -> inaktiv bleiben
        }

        _latchedDirection = Vector2.Normalize(source);
        IsActive = true;
    }

    /// <summary>Bricht Auto-Laufen ab (z. B. bei Kampfbeginn oder Interaktion).</summary>
    public void Cancel() => IsActive = false;

    /// <summary>
    /// Liefert den effektiven Bewegungsvektor für einen Frame. Bei inaktivem Auto-Laufen wird
    /// die Live-Eingabe unverändert durchgereicht.
    /// </summary>
    public Vector2 Resolve(Vector2 liveInput)
    {
        if (!IsActive)
        {
            return liveInput;
        }

        float magnitude = liveInput.Length();
        if (magnitude >= _inputThreshold)
        {
            Vector2 liveDirection = liveInput / magnitude;
            if (Vector2.Dot(liveDirection, _latchedDirection) < _cancelDot)
            {
                IsActive = false;
                return liveInput; // deutliches Gegensteuern -> Kontrolle zurückgeben
            }

            _latchedDirection = liveDirection; // sanftes Lenken
        }

        return _latchedDirection; // volle Laufgeschwindigkeit entlang der Laufrichtung
    }
}
