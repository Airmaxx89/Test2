namespace Aethermoor.Gameplay.Quests;

/// <summary>Lebenszyklus einer Quest.</summary>
public enum QuestState
{
    /// <summary>Noch nicht angenommen.</summary>
    NotStarted = 0,

    /// <summary>Angenommen, Fortschritt läuft.</summary>
    Active = 1,

    /// <summary>Ziel erreicht (Endzustand; Abgabe/Belohnung folgt mit dem Questlog-Ausbau).</summary>
    Completed = 2,
}
