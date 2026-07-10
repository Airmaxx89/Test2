namespace Aethermoor.Core.Diagnostics;

/// <summary>
/// Abstraktion für strukturiertes Logging. Konsumenten programmieren gegen dieses
/// Interface (Dependency-Inversion), damit Log-Senken (Konsole, Datei, Telemetrie)
/// ausgetauscht und in Tests gemockt werden können.
/// </summary>
/// <remarks>
/// <para>
/// <c>category</c> gruppiert Meldungen nach Subsystem (z. B. "Net", "Combat", "World",
/// "UI"), um gezieltes Filtern zu ermöglichen. Direkte <c>GD.Print</c>-Aufrufe im
/// Produktivcode sind untersagt (siehe CODING_STANDARDS §4).
/// </para>
/// </remarks>
public interface IGameLogger
{
    /// <summary>Protokolliert eine Meldung, sofern <paramref name="level"/> aktiv ist.</summary>
    void Log(LogLevel level, string category, string message);

    void Trace(string category, string message);
    void Debug(string category, string message);
    void Info(string category, string message);
    void Warning(string category, string message);
    void Error(string category, string message);
}
