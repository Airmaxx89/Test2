namespace Aethermoor.Core.Events;

/// <summary>
/// Markierungsschnittstelle für alle über den <see cref="EventBus"/> verteilten Ereignisse.
/// </summary>
/// <remarks>
/// Ereignisse sind als unveränderliche Datenträger gedacht (bevorzugt
/// <c>readonly record struct</c> oder <c>sealed record</c>), damit Abonnenten den Zustand
/// nicht gegenseitig verändern können. Sie ermöglichen lose Kopplung zwischen Subsystemen:
/// Ein Sender kennt seine Empfänger nicht (siehe ARCHITECTURE §2.2, Open/Closed-Prinzip).
/// </remarks>
public interface IGameEvent
{
}
