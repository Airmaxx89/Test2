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

    /// <summary>Kein (gültiges) Ziel gewählt (serverseitig geprüft).</summary>
    NoTarget = 5,

    /// <summary>Vom Server aus einem sonstigen Grund abgelehnt.</summary>
    ServerRejected = 6,
}

/// <summary>
/// Übersetzt die Rohtext-Ablehnungsgründe des Match-Handlers
/// (<c>server/modules/src/movement_match.ts</c>) in <see cref="CastFailureReason"/>.
/// Engine-frei und getestet, damit Server- und Client-Vokabular nachweislich
/// zusammenpassen — eine Umbenennung serverseitig fällt im Test auf.
/// </summary>
public static class CastFailureReasonMapper
{
    /// <summary>Bildet einen Server-Grund ab; unbekannte Gründe werden <see cref="CastFailureReason.ServerRejected"/>.</summary>
    public static CastFailureReason FromServerReason(string? reason) => reason switch
    {
        "unknown_ability" => CastFailureReason.UnknownAbility,
        "cooldown" => CastFailureReason.OnCooldown,
        "resource" => CastFailureReason.InsufficientResource,
        "out_of_range" => CastFailureReason.OutOfRange,
        "no_target" or "invalid_target" => CastFailureReason.NoTarget,
        _ => CastFailureReason.ServerRejected,
    };
}
