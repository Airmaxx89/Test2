using System;
using System.Collections.Generic;

namespace Aethermoor.Core.Services;

/// <summary>
/// Schlanke, typsichere Registry für langlebige <see cref="IService"/>-Instanzen.
/// Entkoppelt Konsumenten von konkreten Implementierungen und erleichtert Tests durch
/// Mock-Injektion (siehe ARCHITECTURE §2.2, CODING_STANDARDS §1).
/// </summary>
/// <remarks>
/// <para>
/// Bewusst kein globaler statischer Zustand: Eine Instanz wird vom
/// <see cref="Bootstrap.GameBootstrap"/> gehalten und weitergereicht. Das hält den
/// Lebenszyklus explizit und Tests isoliert.
/// </para>
/// <para>
/// Dienste werden gegen einen Interface-Typ registriert und über denselben Typ aufgelöst.
/// Registrierung erfolgt einmalig beim Bootstrap, danach ist die Nutzung nur lesend —
/// daher ist keine interne Thread-Synchronisierung vorgesehen.
/// </para>
/// </remarks>
public sealed class ServiceLocator
{
    private readonly Dictionary<Type, IService> _services = new();

    /// <summary>
    /// Registriert eine Dienst-Instanz unter dem Interface-Typ <typeparamref name="TService"/>.
    /// </summary>
    /// <exception cref="InvalidOperationException">
    /// Wenn bereits ein Dienst dieses Typs registriert ist (Doppelregistrierung ist ein
    /// Konfigurationsfehler und soll früh auffallen).
    /// </exception>
    public void Register<TService>(TService service) where TService : class, IService
    {
        ArgumentNullException.ThrowIfNull(service);

        Type key = typeof(TService);
        if (_services.ContainsKey(key))
        {
            throw new InvalidOperationException(
                $"Ein Dienst vom Typ '{key.Name}' ist bereits registriert.");
        }

        _services.Add(key, service);
    }

    /// <summary>
    /// Löst den registrierten Dienst vom Typ <typeparamref name="TService"/> auf.
    /// </summary>
    /// <exception cref="InvalidOperationException">
    /// Wenn kein Dienst dieses Typs registriert ist.
    /// </exception>
    public TService Get<TService>() where TService : class, IService
    {
        if (_services.TryGetValue(typeof(TService), out IService? service))
        {
            return (TService)service;
        }

        throw new InvalidOperationException(
            $"Kein Dienst vom Typ '{typeof(TService).Name}' registriert. " +
            "Registrierung erfolgt im GameBootstrap.");
    }

    /// <summary>
    /// Versucht, den Dienst aufzulösen, ohne bei Fehlen eine Ausnahme zu werfen.
    /// </summary>
    /// <returns><c>true</c>, wenn vorhanden; sonst <c>false</c>.</returns>
    public bool TryGet<TService>(out TService? service) where TService : class, IService
    {
        if (_services.TryGetValue(typeof(TService), out IService? found))
        {
            service = (TService)found;
            return true;
        }

        service = null;
        return false;
    }

    /// <summary>Gibt alle registrierten Dienste in Registrierungsreihenfolge zurück.</summary>
    public IReadOnlyCollection<IService> All => _services.Values;

    /// <summary>Entfernt alle Registrierungen (z. B. zwischen Tests).</summary>
    public void Clear() => _services.Clear();
}
