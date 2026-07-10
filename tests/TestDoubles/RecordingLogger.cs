using System.Collections.Generic;
using Aethermoor.Core.Diagnostics;

namespace Aethermoor.Tests.TestDoubles;

/// <summary>
/// Test-Double für <see cref="IGameLogger"/>, das alle Meldungen aufzeichnet, statt sie
/// auszugeben. Ermöglicht Assertions darüber, ob und wie Subsysteme protokollieren
/// (z. B. dass der <c>EventBus</c> Handler-Ausnahmen als Fehler loggt).
/// </summary>
public sealed class RecordingLogger : IGameLogger
{
    public readonly record struct Entry(LogLevel Level, string Category, string Message);

    private readonly List<Entry> _entries = new();

    public IReadOnlyList<Entry> Entries => _entries;

    public void Log(LogLevel level, string category, string message)
        => _entries.Add(new Entry(level, category, message));

    public void Trace(string category, string message) => Log(LogLevel.Trace, category, message);
    public void Debug(string category, string message) => Log(LogLevel.Debug, category, message);
    public void Info(string category, string message) => Log(LogLevel.Info, category, message);
    public void Warning(string category, string message) => Log(LogLevel.Warning, category, message);
    public void Error(string category, string message) => Log(LogLevel.Error, category, message);
}
