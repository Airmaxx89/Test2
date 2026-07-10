# Gameplay-Modul

Kampf, Charakter, Fähigkeiten, Progression und Quests. Darf von `World` und `Core`
abhängen, **nie** von `UI`. Kommunikation nach oben ausschließlich über den `EventBus`.

Geplante Unterordner (ab Milestone 4):
`Combat/`, `Character/`, `Abilities/`, `Quests/`. Inhalte werden datengetrieben über
Godot-`Resource`-Definitionen beschrieben (siehe docs/ARCHITECTURE.md §4).
