namespace Aethermoor.Gameplay.Targeting;

/// <summary>
/// Liefert der Zauberleiste die Distanz zum aktuellen Ziel für die Reichweitenprüfung
/// beim Wirken. Entkoppelt die Leiste vom konkreten Zielsystem (Dependency-Inversion).
/// </summary>
public interface ITargetDistanceProvider
{
    /// <summary>
    /// Distanz zum aktuellen Ziel in Weltpixeln, oder <see cref="float.PositiveInfinity"/>,
    /// wenn kein Ziel gewählt ist — gezielte Fähigkeiten schlagen dann mit
    /// <c>OutOfRange</c> fehl, ungezielte (Range ≤ 0) bleiben wirkbar.
    /// </summary>
    float DistanceToTarget { get; }
}
