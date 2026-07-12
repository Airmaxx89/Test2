using System;
using System.Globalization;
using Godot;

namespace Aethermoor.Core.Diagnostics;

/// <summary>
/// Godot-basierte Standardimplementierung von <see cref="IGameLogger"/>. Schreibt
/// formatierte, kategorisierte Zeilen in die Godot-Ausgabe und leitet
/// <see cref="LogLevel.Warning"/>/<see cref="LogLevel.Error"/> zusätzlich an die
/// Godot-Fehlerkanäle weiter (bessere Sichtbarkeit im Editor/Debugger).
/// </summary>
/// <remarks>
/// Meldungen unterhalb von <see cref="MinimumLevel"/> werden verworfen. Für
/// Release-Builds wird die Mindeststufe angehoben, um Overhead zu vermeiden
/// (siehe ARCHITECTURE §7).
/// </remarks>
public sealed class GodotGameLogger : IGameLogger
{
    private readonly LogLevel _minimumLevel;

    /// <param name="minimumLevel">
    /// Niedrigste Stufe, die noch ausgegeben wird. Meldungen darunter werden verworfen.
    /// </param>
    public GodotGameLogger(LogLevel minimumLevel = LogLevel.Info)
    {
        _minimumLevel = minimumLevel;
    }

    /// <summary>Die aktuell wirksame Mindest-Ausgabestufe.</summary>
    public LogLevel MinimumLevel => _minimumLevel;

    public void Log(LogLevel level, string category, string message)
    {
        if (level < _minimumLevel)
        {
            return;
        }

        string line = Format(level, category, message);

        switch (level)
        {
            case LogLevel.Warning:
                GD.PushWarning(line);
                GD.Print(line);
                break;
            case LogLevel.Error:
                GD.PushError(line);
                GD.PrintErr(line);
                break;
            default:
                GD.Print(line);
                break;
        }
    }

    public void Trace(string category, string message) => Log(LogLevel.Trace, category, message);
    public void Debug(string category, string message) => Log(LogLevel.Debug, category, message);
    public void Info(string category, string message) => Log(LogLevel.Info, category, message);
    public void Warning(string category, string message) => Log(LogLevel.Warning, category, message);
    public void Error(string category, string message) => Log(LogLevel.Error, category, message);

    private static string Format(LogLevel level, string category, string message)
    {
        // Beispiel: "12:34:56.789 [INFO ] [Net] Session hergestellt"
        string time = DateTime.Now.ToString("HH:mm:ss.fff", CultureInfo.InvariantCulture);
        return $"{time} [{level,-5}] [{category}] {message}";
    }
}
