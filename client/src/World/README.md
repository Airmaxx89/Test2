# World-Modul

Zonen, Weltstreaming, LOD-Steuerung, Wetter, Tag/Nacht-Zyklus, Vegetation und Spawns.
Darf nur von `Core` abhängen. Trägt die Hauptlast des Performance-Budgets
(siehe docs/ARCHITECTURE.md §6).

Geplante Unterordner (ab Milestone 4): `Streaming/`, `Environment/`.
Jede Zone ist ein eigenständiges, gestreamtes Weltmodul mit eigenem Manifest.
