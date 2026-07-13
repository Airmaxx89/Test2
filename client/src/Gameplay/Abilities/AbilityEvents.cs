using Aethermoor.Core.Events;

namespace Aethermoor.Gameplay.Abilities;

/// <summary>
/// Wird veröffentlicht, wenn der Client eine Fähigkeit erfolgreich (prädiktiv) gewirkt hat.
/// „Prädiktiv", weil die verbindliche Auflösung serverseitig erfolgt (ADR-0002) — Audio/VFX
/// dürfen darauf sofort reagieren, Spielzustand nicht.
/// </summary>
public readonly record struct AbilityCastPredictedEvent(AbilityDefinition Ability) : IGameEvent;

/// <summary>
/// Wird veröffentlicht, wenn ein Wirkversuch clientseitig abgelehnt wurde — Grundlage für
/// Spieler-Feedback („Nicht genug Mana", Button-Wackeln, Fehlklang).
/// </summary>
public readonly record struct AbilityCastRejectedEvent(string AbilityId, CastFailureReason Reason) : IGameEvent;
