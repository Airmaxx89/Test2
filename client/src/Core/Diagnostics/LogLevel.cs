namespace Aethermoor.Core.Diagnostics;

/// <summary>
/// Schweregrade für strukturiertes Logging. In Release-Builds können
/// <see cref="Trace"/> und <see cref="Debug"/> herausgefiltert werden,
/// um Performance und Log-Rauschen zu minimieren (siehe ARCHITECTURE §7).
/// </summary>
public enum LogLevel
{
    Trace = 0,
    Debug = 1,
    Info = 2,
    Warning = 3,
    Error = 4,
}
