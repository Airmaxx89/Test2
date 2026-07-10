using Aethermoor.Core.Events;

namespace Aethermoor.Core.Bootstrap;

/// <summary>
/// Wird einmalig veröffentlicht, sobald der Kern (Logging, Dienste, EventBus) vollständig
/// initialisiert ist. Subsysteme, die auf einen fertigen Kern warten, abonnieren dieses
/// Ereignis, anstatt sich auf Godot-Initialisierungsreihenfolgen zu verlassen.
/// </summary>
public readonly record struct GameInitializedEvent(ulong TimestampMsec) : IGameEvent;
