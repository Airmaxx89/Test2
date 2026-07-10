using Aethermoor.Core.Configuration;
using Aethermoor.Core.Diagnostics;
using Aethermoor.Core.Events;
using Aethermoor.Core.Services;
using Godot;

namespace Aethermoor.Core.Bootstrap;

/// <summary>
/// Einziger globaler Einstiegspunkt der Anwendung (Godot-Autoload "Game").
/// Baut den Kern in fester, nachvollziehbarer Reihenfolge auf — Logging, dann
/// <see cref="ServiceLocator"/>, dann <see cref="EventBus"/> — und stellt diese
/// dem restlichen Spiel als zentrale Einstiegspunkte bereit.
/// </summary>
/// <remarks>
/// <para>
/// Kein anderer Code führt globale Initialisierung durch (siehe ARCHITECTURE §2.2).
/// Höhere Schichten holen sich Dienste über <see cref="Services"/> und kommunizieren
/// über <see cref="Events"/>, statt harte Referenzen aufzubauen.
/// </para>
/// <para>
/// Gameplay- und Domänen-Dienste (Netzwerk, Audio, Weltstreaming) werden in späteren
/// Milestones hier registriert — an genau einer Stelle und in kontrollierter Reihenfolge.
/// </para>
/// </remarks>
public sealed partial class GameBootstrap : Node
{
    private const string LogCategory = "Bootstrap";
    private const string ConfigPath = "res://config/game_config.tres";

    /// <summary>Die geladene Laufzeitkonfiguration dieser Sitzung.</summary>
    public GameConfig Config { get; private set; } = null!;

    /// <summary>Der aktive Dienst-Locator dieser Sitzung.</summary>
    public ServiceLocator Services { get; } = new();

    /// <summary>Die zentrale Ereignis-Zentrale dieser Sitzung.</summary>
    public EventBus Events { get; private set; } = null!;

    /// <summary>Der zentrale Logger dieser Sitzung.</summary>
    public IGameLogger Logger { get; private set; } = null!;

    /// <summary>
    /// Godot-Lebenszyklus: wird beim Laden des Autoloads aufgerufen. Baut den Kern auf.
    /// </summary>
    public override void _Ready()
    {
        Config = LoadConfigOrDefault(out bool usedFallbackConfig);
        Logger = new GodotGameLogger(Config.MinimumLogLevel);

        Logger.Info(LogCategory, "Kern-Initialisierung gestartet.");
        if (usedFallbackConfig)
        {
            Logger.Warning(
                LogCategory,
                $"Konfiguration '{ConfigPath}' nicht ladbar — Standardwerte werden verwendet.");
        }

        ApplyClientSettings(Config);

        Events = new EventBus(Logger);

        // Domänen-Dienste werden in kommenden Milestones hier registriert und initialisiert,
        // z. B.:  Services.Register<INetworkService>(new NakamaNetworkService(...));
        InitializeRegisteredServices();

        Logger.Info(LogCategory, "Kern-Initialisierung abgeschlossen.");
        Events.Publish(new GameInitializedEvent(Time.GetTicksMsec()));
    }

    /// <summary>
    /// Godot-Lebenszyklus: wird beim Beenden aufgerufen. Fährt Dienste in umgekehrter
    /// Registrierungsreihenfolge herunter und räumt Abonnements ab.
    /// </summary>
    public override void _ExitTree()
    {
        // Bei einem Autoload läuft _Ready stets vor _ExitTree, daher sind die
        // Kernreferenzen hier bereits initialisiert.
        ShutdownRegisteredServices();
        Events.Clear();
        Logger.Info(LogCategory, "Kern heruntergefahren.");
    }

    private static GameConfig LoadConfigOrDefault(out bool usedFallback)
    {
        if (ResourceLoader.Exists(ConfigPath)
            && ResourceLoader.Load<GameConfig>(ConfigPath) is GameConfig config)
        {
            usedFallback = false;
            return config;
        }

        usedFallback = true;
        return new GameConfig();
    }

    private void ApplyClientSettings(GameConfig config)
    {
        // Akku-/Energieschonung: harte FPS-Obergrenze gemäß Konfiguration (ARCHITECTURE §6).
        Engine.MaxFps = config.TargetFrameRate;
        Logger.Debug(LogCategory, $"Ziel-Bildrate auf {config.TargetFrameRate} FPS gesetzt.");
    }

    private void InitializeRegisteredServices()
    {
        foreach (IService service in Services.All)
        {
            service.Initialize();
        }
    }

    private void ShutdownRegisteredServices()
    {
        // Umgekehrte Reihenfolge: Abhängige zuerst herunterfahren.
        var services = new System.Collections.Generic.List<IService>(Services.All);
        for (int i = services.Count - 1; i >= 0; i--)
        {
            services[i].Shutdown();
        }
    }
}
