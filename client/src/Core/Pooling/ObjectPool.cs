using System;
using System.Collections.Generic;

namespace Aethermoor.Core.Pooling;

/// <summary>
/// Wiederverwendbarer, allokationssparender Objektpool für kurzlebige Objekte, die in
/// Hot-Loops entstehen (Projektile, Schadenszahlen, VFX, Gegner). Vermeidet GC-Druck und
/// gehört zum verbindlichen Performance-Werkzeugkasten (siehe ARCHITECTURE §6,
/// CODING_STANDARDS §7).
/// </summary>
/// <remarks>
/// <para>
/// Bewusst Godot-frei gehalten, damit die Pool-Logik ohne Engine in CI unit-getestet werden
/// kann. Godot-spezifische Node-Pools bauen auf diesem Kern auf (späterer Milestone).
/// </para>
/// <para>
/// Nicht thread-sicher: Der Client verwaltet Pools pro Subsystem im Spiel-Thread. Über eine
/// optionale Obergrenze (<c>maxSize</c>) werden zurückgegebene Objekte verworfen, statt den
/// Speicher unbegrenzt wachsen zu lassen.
/// </para>
/// </remarks>
/// <typeparam name="T">Verwalteter Referenztyp.</typeparam>
public sealed class ObjectPool<T> where T : class
{
    private readonly Stack<T> _available = new();
    private readonly Func<T> _factory;
    private readonly Action<T>? _onRent;
    private readonly Action<T>? _onReturn;
    private readonly int _maxSize;

    /// <param name="factory">Erzeugt eine neue Instanz, wenn der Pool leer ist. Pflicht.</param>
    /// <param name="onRent">Optionaler Rückruf beim Entnehmen (zusätzlich zu <see cref="IPoolable"/>).</param>
    /// <param name="onReturn">Optionaler Rückruf beim Zurückgeben (zusätzlich zu <see cref="IPoolable"/>).</param>
    /// <param name="prewarm">Anzahl vorab erzeugter Instanzen, um Spitzen zu vermeiden.</param>
    /// <param name="maxSize">
    /// Obergrenze zwischengehaltener Instanzen. Darüber hinaus zurückgegebene Objekte werden
    /// verworfen (der GC übernimmt). Standard: unbegrenzt.
    /// </param>
    /// <exception cref="ArgumentNullException">Wenn <paramref name="factory"/> null ist.</exception>
    /// <exception cref="ArgumentOutOfRangeException">
    /// Wenn <paramref name="prewarm"/> negativ oder <paramref name="maxSize"/> kleiner als 1 ist.
    /// </exception>
    public ObjectPool(
        Func<T> factory,
        Action<T>? onRent = null,
        Action<T>? onReturn = null,
        int prewarm = 0,
        int maxSize = int.MaxValue)
    {
        ArgumentNullException.ThrowIfNull(factory);
        ArgumentOutOfRangeException.ThrowIfNegative(prewarm);
        ArgumentOutOfRangeException.ThrowIfLessThan(maxSize, 1);

        _factory = factory;
        _onRent = onRent;
        _onReturn = onReturn;
        _maxSize = maxSize;

        int initial = Math.Min(prewarm, maxSize);
        for (int i = 0; i < initial; i++)
        {
            _available.Push(_factory());
        }
    }

    /// <summary>Anzahl derzeit im Pool verfügbarer (nicht entliehener) Instanzen.</summary>
    public int CountAvailable => _available.Count;

    /// <summary>Anzahl aktuell entliehener, noch nicht zurückgegebener Instanzen.</summary>
    public int CountInUse { get; private set; }

    /// <summary>
    /// Entnimmt eine Instanz (oder erzeugt eine neue, falls der Pool leer ist) und bereitet
    /// sie über <see cref="IPoolable.OnRent"/> und den optionalen Rent-Rückruf vor.
    /// </summary>
    public T Rent()
    {
        T item = _available.Count > 0 ? _available.Pop() : _factory();
        CountInUse++;

        if (item is IPoolable poolable)
        {
            poolable.OnRent();
        }

        _onRent?.Invoke(item);
        return item;
    }

    /// <summary>
    /// Gibt eine zuvor entliehene Instanz zurück. Setzt sie über <see cref="IPoolable.OnReturn"/>
    /// und den optionalen Return-Rückruf zurück und hält sie bis zur Obergrenze vor.
    /// </summary>
    /// <exception cref="ArgumentNullException">Wenn <paramref name="item"/> null ist.</exception>
    /// <exception cref="InvalidOperationException">
    /// Wenn mehr Objekte zurückgegeben als entliehen wurden (Anzeichen eines Doppel-Return-Fehlers).
    /// </exception>
    public void Return(T item)
    {
        ArgumentNullException.ThrowIfNull(item);

        if (CountInUse == 0)
        {
            throw new InvalidOperationException(
                "Es wurde ein Objekt zurückgegeben, das nicht (mehr) als entliehen gilt.");
        }

        CountInUse--;

        if (item is IPoolable poolable)
        {
            poolable.OnReturn();
        }

        _onReturn?.Invoke(item);

        if (_available.Count < _maxSize)
        {
            _available.Push(item);
        }
    }

    /// <summary>Leert die vorgehaltenen Instanzen (die entliehenen bleiben unberührt).</summary>
    public void Clear() => _available.Clear();
}
