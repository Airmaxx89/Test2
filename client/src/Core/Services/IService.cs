namespace Aethermoor.Core.Services;

/// <summary>
/// Markierungs- und Lebenszyklus-Vertrag für langlebige Dienste, die über den
/// <see cref="ServiceLocator"/> aufgelöst werden (z. B. Netzwerk, Audio, Weltstreaming).
/// </summary>
/// <remarks>
/// Dienste kapseln querschnittliche Fähigkeiten und werden gegen ein Interface
/// registriert, damit Konsumenten von konkreten Implementierungen entkoppelt bleiben
/// (Dependency-Inversion, siehe ARCHITECTURE §2.2).
/// </remarks>
public interface IService
{
    /// <summary>
    /// Wird nach der Registrierung genau einmal aufgerufen. Hier richtet der Dienst
    /// seinen Zustand ein. Reihenfolge und Aufruf verantwortet der
    /// <see cref="Bootstrap.GameBootstrap"/>.
    /// </summary>
    void Initialize();

    /// <summary>
    /// Wird beim Herunterfahren aufgerufen (umgekehrte Registrierungsreihenfolge).
    /// Gibt Ressourcen frei, trennt Verbindungen, meldet Callbacks ab.
    /// </summary>
    void Shutdown();
}
