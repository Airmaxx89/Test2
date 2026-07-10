namespace Aethermoor.Core.Pooling;

/// <summary>
/// Optionaler Vertrag für Objekte, die von einem <see cref="ObjectPool{T}"/> verwaltet
/// werden. Implementierende Typen erhalten Lebenszyklus-Rückrufe beim Entnehmen und
/// Zurückgeben, um ihren Zustand zurückzusetzen (z. B. Projektile, Schadenszahlen, VFX).
/// </summary>
/// <remarks>
/// Die Implementierung ist freiwillig: Der Pool funktioniert auch mit beliebigen
/// Referenztypen und optionalen Rückruf-Delegaten. Wo ein Typ jedoch selbst weiß, wie er
/// sich zurücksetzt, hält <see cref="IPoolable"/> diese Logik gekapselt (SOLID-SRP).
/// </remarks>
public interface IPoolable
{
    /// <summary>Wird aufgerufen, unmittelbar bevor das Objekt aus dem Pool entnommen wird.</summary>
    void OnRent();

    /// <summary>Wird aufgerufen, unmittelbar bevor das Objekt in den Pool zurückkehrt.</summary>
    void OnReturn();
}
