using Aethermoor.Core.Diagnostics;
using Godot;

namespace Aethermoor.Core.Configuration;

/// <summary>
/// Zentrale, typsichere Laufzeitkonfiguration des Clients. Als Godot-<see cref="Resource"/>
/// im Editor bearbeitbar und als <c>.tres</c> versionierbar. Wird vom
/// <see cref="Bootstrap.GameBootstrap"/> geladen; fehlt die Datei, greifen die hier
/// definierten Standardwerte (siehe ARCHITECTURE §7 — keine verstreuten Magic Numbers).
/// </summary>
/// <remarks>
/// Balancing-/fairnessrelevante Werte gehören <b>nicht</b> hierher, sondern auf den Server
/// (ADR-0002). Diese Resource hält reine Client-Betriebsparameter.
/// </remarks>
[GlobalClass]
public partial class GameConfig : Resource
{
    /// <summary>Niedrigste Log-Stufe, die noch ausgegeben wird.</summary>
    [Export] public LogLevel MinimumLogLevel { get; set; } = LogLevel.Info;

    /// <summary>Ziel-Bildrate (FPS-Cap). Schont Akku auf Mobilgeräten.</summary>
    [Export(PropertyHint.Range, "30,120,1")] public int TargetFrameRate { get; set; } = 60;

    /// <summary>Host des Nakama-Backends (Standard: lokale Entwicklung).</summary>
    [Export] public string NakamaHost { get; set; } = "127.0.0.1";

    /// <summary>Port des Nakama-Backends.</summary>
    [Export] public int NakamaPort { get; set; } = 7350;

    /// <summary>Server-Key für Nakama. Nur lokaler Entwicklungswert — Prod via Secret.</summary>
    [Export] public string NakamaServerKey { get; set; } = "defaultkey";

    /// <summary>Ob die Nakama-Verbindung TLS verwendet (in Produktion: true).</summary>
    [Export] public bool NakamaUseSsl { get; set; }
}
