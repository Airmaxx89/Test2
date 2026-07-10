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

    // In Debug-Builds ausführlicher; in Release wird das Log ruhiger (ARCHITECTURE §7).
#if DEBUG
    private const LogLevel MinimumLogLevel = LogLevel.Debug;
#else
    private const LogLevel MinimumLogLevel = LogLevel.Info;
#endif

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
        Logger = new GodotGameLogger(MinimumLogLevel);
        Logger.Info(LogCategory, "Kern-Initialisierung gestartet.");

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
        ShutdownRegisteredServices();
        Events?.Clear();
        Logger?.Info(LogCategory, "Kern heruntergefahren.");
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
