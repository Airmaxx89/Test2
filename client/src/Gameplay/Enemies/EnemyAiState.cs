namespace Aethermoor.Gameplay.Enemies;

/// <summary>Zustände der Gegner-KI (GAME_DESIGN §8).</summary>
public enum EnemyAiState
{
    /// <summary>Läuft die Patrouillenroute ab (oder steht, wenn keine definiert ist).</summary>
    Patrol = 0,

    /// <summary>Verfolgt einen Spieler (Aggro).</summary>
    Chase = 1,

    /// <summary>In Angriffsreichweite: steht und greift an.</summary>
    Attack = 2,

    /// <summary>Kehrt zum Heimatpunkt zurück und ignoriert dabei Aggro (Heimkehr/Reset).</summary>
    Return = 3,
}
