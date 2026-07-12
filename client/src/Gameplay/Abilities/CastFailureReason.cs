namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Warum ein Wirkversuch abgelehnt wurde. Die UI übersetzt dies in Spieler-Feedback
/// (ausgegrauter Button, „Zu weit entfernt", „Nicht genug Mana").
/// </summary>
public enum CastFailureReason
{
    /// <summary>Kein Fehler — der Wirkversuch war erfolgreich.</summary>
    None = 0,

    /// <summary>Die Fähigkeit ist dem Charakter nicht bekannt.</summary>
    UnknownAbility = 1,

    /// <summary>Die Abklingzeit läuft noch.</summary>
    OnCooldown = 2,

    /// <summary>Nicht genug Ressource (Mana/Wut/Energie).</summary>
    InsufficientResource = 3,

    /// <summary>Das Ziel ist außerhalb der Wirkreichweite.</summary>
    OutOfRange = 4,
}
