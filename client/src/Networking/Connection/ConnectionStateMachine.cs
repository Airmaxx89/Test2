using System;
using System.Collections.Generic;

namespace Aethermoor.Networking.Connection;

/// <summary>Beschreibt einen Zustandsübergang der Verbindung.</summary>
public readonly record struct ConnectionStateChange(ConnectionState Previous, ConnectionState Current);

/// <summary>
/// Zustandsmaschine der Verbindung mit klar definierten, validierten Übergängen. Verhindert
/// ungültige Zustandssprünge (z. B. „Disconnected → Connected" ohne Verbindungsaufbau) und
/// macht das Verbindungsverhalten testbar und nachvollziehbar.
/// </summary>
/// <remarks>
/// Engine- und SDK-frei (siehe ADR-0002, ARCHITECTURE §8). Der Nakama-Adapter wie auch der
/// Offline-Stand-in treiben diese Maschine und übersetzen ihre Übergänge in EventBus-Ereignisse.
/// </remarks>
public sealed class ConnectionStateMachine
{
    private static readonly IReadOnlyDictionary<ConnectionState, ConnectionState[]> AllowedTransitions =
        new Dictionary<ConnectionState, ConnectionState[]>
        {
            [ConnectionState.Disconnected] = new[] { ConnectionState.Connecting },
            [ConnectionState.Connecting] = new[]
            {
                ConnectionState.Connected, ConnectionState.Failed, ConnectionState.Disconnected,
            },
            [ConnectionState.Connected] = new[]
            {
                ConnectionState.Reconnecting, ConnectionState.Disconnected,
            },
            [ConnectionState.Reconnecting] = new[]
            {
                ConnectionState.Connected, ConnectionState.Failed, ConnectionState.Disconnected,
            },
            [ConnectionState.Failed] = new[]
            {
                ConnectionState.Connecting, ConnectionState.Disconnected,
            },
        };

    /// <summary>Aktueller Zustand.</summary>
    public ConnectionState Current { get; private set; } = ConnectionState.Disconnected;

    /// <summary>Wird nach jedem erfolgreichen Übergang ausgelöst.</summary>
    public event Action<ConnectionStateChange>? Changed;

    /// <summary>Prüft, ob der Übergang in den angegebenen Zustand erlaubt ist.</summary>
    public bool CanTransitionTo(ConnectionState next)
        => AllowedTransitions.TryGetValue(Current, out ConnectionState[]? targets)
           && Array.IndexOf(targets, next) >= 0;

    /// <summary>Führt den Übergang aus.</summary>
    /// <exception cref="InvalidOperationException">Wenn der Übergang nicht erlaubt ist.</exception>
    public void TransitionTo(ConnectionState next)
    {
        if (!CanTransitionTo(next))
        {
            throw new InvalidOperationException(
                $"Ungültiger Verbindungsübergang: {Current} → {next}.");
        }

        var change = new ConnectionStateChange(Current, next);
        Current = next;
        Changed?.Invoke(change);
    }

    /// <summary>Führt den Übergang aus, sofern erlaubt; sonst geschieht nichts.</summary>
    /// <returns><c>true</c>, wenn der Übergang stattfand.</returns>
    public bool TryTransitionTo(ConnectionState next)
    {
        if (!CanTransitionTo(next))
        {
            return false;
        }

        TransitionTo(next);
        return true;
    }
}
