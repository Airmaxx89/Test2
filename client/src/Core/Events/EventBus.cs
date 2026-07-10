using System;
using System.Collections.Generic;
using Aethermoor.Core.Diagnostics;

namespace Aethermoor.Core.Events;

/// <summary>
/// Typisierte Publish/Subscribe-Zentrale für systemübergreifende Ereignisse. Entkoppelt
/// Sender und Empfänger: Gameplay kann etwa <c>PlayerDamagedEvent</c> feuern, ohne die UI
/// zu kennen (siehe ARCHITECTURE §2.2, CODING_STANDARDS §1).
/// </summary>
/// <remarks>
/// <para>
/// Handler werden pro konkretem Ereignistyp verwaltet. Beim <see cref="Publish{TEvent}"/>
/// wird über eine Kopie der Handlerliste iteriert, damit Ab-/Anmeldungen während der
/// Zustellung sicher sind. Eine Ausnahme in einem Handler wird protokolliert und
/// unterbricht nicht die Zustellung an die übrigen Handler.
/// </para>
/// <para>
/// Für per-Frame-Hochfrequenzpfade (Bewegung/Render) ist der EventBus bewusst nicht
/// gedacht — dort werden direkte Aufrufe oder gepoolte Strukturen verwendet, um
/// Allokationen zu vermeiden (CODING_STANDARDS §7).
/// </para>
/// </remarks>
public sealed class EventBus
{
    private const string LogCategory = "Events";

    private readonly Dictionary<Type, List<Delegate>> _handlers = new();
    private readonly IGameLogger _logger;

    public EventBus(IGameLogger logger)
    {
        ArgumentNullException.ThrowIfNull(logger);
        _logger = logger;
    }

    /// <summary>Meldet einen Handler für Ereignisse vom Typ <typeparamref name="TEvent"/> an.</summary>
    public void Subscribe<TEvent>(Action<TEvent> handler) where TEvent : IGameEvent
    {
        ArgumentNullException.ThrowIfNull(handler);

        Type key = typeof(TEvent);
        if (!_handlers.TryGetValue(key, out List<Delegate>? list))
        {
            list = new List<Delegate>();
            _handlers.Add(key, list);
        }

        if (!list.Contains(handler))
        {
            list.Add(handler);
        }
    }

    /// <summary>Meldet einen zuvor angemeldeten Handler wieder ab.</summary>
    public void Unsubscribe<TEvent>(Action<TEvent> handler) where TEvent : IGameEvent
    {
        ArgumentNullException.ThrowIfNull(handler);

        if (_handlers.TryGetValue(typeof(TEvent), out List<Delegate>? list))
        {
            list.Remove(handler);
        }
    }

    /// <summary>
    /// Stellt ein Ereignis synchron an alle angemeldeten Handler zu. Ausnahmen einzelner
    /// Handler werden protokolliert; die Zustellung an weitere Handler läuft weiter.
    /// </summary>
    public void Publish<TEvent>(TEvent gameEvent) where TEvent : IGameEvent
    {
        if (!_handlers.TryGetValue(typeof(TEvent), out List<Delegate>? list) || list.Count == 0)
        {
            return;
        }

        // Snapshot: erlaubt (Ab-)Anmeldungen von Handlern während der Zustellung.
        Delegate[] snapshot = list.ToArray();
        foreach (Delegate handler in snapshot)
        {
            try
            {
                ((Action<TEvent>)handler).Invoke(gameEvent);
            }
            catch (Exception ex)
            {
                _logger.Error(
                    LogCategory,
                    $"Handler für '{typeof(TEvent).Name}' hat eine Ausnahme geworfen: {ex}");
            }
        }
    }

    /// <summary>Entfernt alle Abonnements (z. B. beim Herunterfahren oder in Tests).</summary>
    public void Clear() => _handlers.Clear();
}
