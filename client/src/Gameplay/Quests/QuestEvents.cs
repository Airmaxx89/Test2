using Aethermoor.Core.Events;

namespace Aethermoor.Gameplay.Quests;

/// <summary>
/// Fortschrittsmeldung der aktiven Quest (HUD-Anzeige, später Questlog). Wird beim Start
/// und bei jeder Änderung veröffentlicht.
/// </summary>
public readonly record struct QuestProgressEvent(
    string Title,
    int Current,
    int Required,
    bool Completed) : IGameEvent;
