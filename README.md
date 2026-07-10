# Aetheria — Mobile Fantasy Action-RPG (Godot 4.3+)

Ein **offline Singleplayer**, WoW-ähnliches Fantasy-Action-RPG-Prototyp, von Grund
auf für **Android Mid-Range-Geräte (60 FPS)** gebaut. Kein Netzwerk, kein Server —
alles lokal und persistent.

> **Sofort lauffähig ohne Assets:** Der Prototyp nutzt prozedurale Platzhalter-Meshes
> (Kapseln, Kegel, Boxen) und eingefärbte Materialien. Audio-/Textur-Assets sind
> optional und werden defensiv geladen (kein Crash, wenn sie fehlen).

---

## 1. Gesamtübersicht & Projekt-Setup

### Schnellstart
1. **Godot 4.3+** (Standard-Version, nicht .NET nötig) herunterladen: <https://godotengine.org>
2. Godot öffnen → **Import** → diese `project.godot` auswählen → **Import & Edit**.
3. Beim ersten Öffnen re-importiert Godot Assets automatisch (`.godot/` wird erzeugt).
4. **F5** (Play) drücken → Hauptmenü → *Neues Spiel* → Klasse wählen → los.

### Gameplay-Loop
Erkunde **Eichenhain** (ein ~200×200 m Wald-/Dorf-Areal mit Ruinen) → sprich mit
NPCs (`!`-Symbol) für Quests → töte Mobs, sammle Loot & Quest-Items → level auf
(bis Level 20) → schalte Skills frei → schließe die Quest-Kette bis zum Boss ab.

### Ordner-Struktur
```
res://
├── project.godot            # Engine-Config (Mobile-Renderer, Autoloads, Input, Layer)
├── export_presets.cfg       # Fertiges Android-Export-Preset (arm64, ETC2/ASTC)
├── icon.svg
├── scripts/
│   ├── autoload/            # Singletons: Events, Database, GameManager, AudioManager,
│   │                        #             SaveManager, QuestTracker, PoolManager
│   ├── resources/           # Daten-Klassen: ItemData, SkillData, ClassData,
│   │                        #                QuestData, EnemyData
│   ├── player/              # PlayerController (Touch), CameraRig (3rd-Person)
│   ├── combat/              # CombatSystem, Projectile (gepoolt), HitEffect
│   ├── enemies/             # Enemy (FSM-AI), HealthBar3D
│   ├── systems/             # LevelingSystem, InventorySystem
│   ├── quests/              # (Erweiterungsraum)
│   ├── world/               # World, EnemySpawner, MultiMeshScatter, NPC, EscortNPC
│   └── ui/                  # HUD, VirtualJoystick, TouchButton, Minimap,
│                            # QuestJournal, InventoryPanel, DialogPanel, Menüs, Tutorial
├── scenes/
│   ├── main/main.tscn       # Einstiegsszene (Menü → Spiel)
│   ├── player/              # player.tscn, camera_rig.tscn
│   ├── enemies/enemy.tscn
│   ├── combat/              # projectile.tscn, hit_effect.tscn
│   ├── props/loot_drop.tscn
│   ├── world/               # world.tscn, npc.tscn, escort_npc.tscn, default_env.tres
│   └── ui/                  # ui_hud.tscn, quest_journal, inventory_panel, dialog,
│                            # tutorial_overlay, main_menu, character_creation, damage_number
├── resources/               # Optionale echte .tres (überschreiben Code-Defaults)
├── assets/                  # audio/, textures/, models/, fonts/ (+ README-Anleitungen)
└── docs/SETUP.md            # Detaillierte Checkliste
```

### Architektur-Prinzipien
- **Event-Bus (`Events`)** entkoppelt alle Systeme (kein `get_node`-Spaghetti).
- **`Database`** hält alle statischen Daten (Klassen/Skills/Items/Enemies/Quests),
  prozedural erzeugt → sofort spielbar, später durch `.tres` überschreibbar.
- **Autoload-Reihenfolge** ist bewusst gewählt (Events & Database zuerst).
- **Komponenten am Spieler**: `CombatSystem`, `InventorySystem`, `LevelingSystem`
  als Kind-Nodes → modular und testbar.

---

## 2. Wichtige Skripte (vollständig im Repo)

| System | Datei | Aufgabe |
|--------|-------|---------|
| Event-Bus | `scripts/autoload/events.gd` | Zentrale Signale |
| Spielstand | `scripts/autoload/game_manager.gd` | Charakter-State, FPS-Cap |
| Daten | `scripts/autoload/database.gd` | Klassen/Skills/Items/Enemies/Quests |
| Audio | `scripts/autoload/audio_manager.gd` | Gepoolte AudioPlayer |
| Speichern | `scripts/autoload/save_manager.gd` | JSON Save/Load (`user://`) |
| Quests | `scripts/autoload/quest_tracker.gd` | Quest-Zustände & Fortschritt |
| Pooling | `scripts/autoload/pool_manager.gd` | Generisches Object-Pooling |
| Spieler | `scripts/player/player_controller.gd` | Touch+WASD-Movement |
| Kamera | `scripts/player/camera_rig.gd` | Drag-Rotation + Pinch-Zoom |
| Kampf | `scripts/combat/combat_system.gd` | Auto-Attack, Skills, Cooldowns |
| Gegner | `scripts/enemies/enemy.gd` | FSM: Idle→Chase→Attack→Return |
| Leveln | `scripts/systems/leveling_system.gd` | XP-Kurve, Stat-/Skill-Freischaltung |
| Inventar | `scripts/systems/inventory_system.gd` | Stacks, Equipment, Verbrauch |
| UI | `scripts/ui/hud.gd` | Bindet Touch-Controls, Vitals, Hotbar |

Alle Skripte sind **kommentiert** und enthalten Performance-Hinweise direkt am Code.

---

## 3. Szenen-Aufbau

- **`main.tscn`** — `Main` (Node) + `UILayer` (HUD) + `MenuLayer` (Menü/Char-Creation).
  Steuert Fluss: Menü → Charaktererstellung → Welt+HUD, Auto-Save alle 60 s
  sowie beim App-Pausieren (mobil wichtig).
- **`world.tscn`** — Terrain (200×200), `DirectionalLight3D` (Schatten), Ruinen-Wände,
  `MultiMeshScatter` (100 Bäume = **1 Draw Call**), NPCs (Aldric, Mira),
  Escort-Ziel, 8 `EnemySpawner` (Wölfe/Banditen/Schützen/Geister/Boss).
- **`player.tscn`** — `CharacterBody3D` + Combat/Inventory/Leveling-Komponenten +
  `InteractionArea`.
- **`camera_rig.tscn`** — Yaw→Pitch→`SpringArm3D`→`Camera3D` (Wand-Clipping-Schutz).
- **`enemy.tscn`** — Body, `DetectionArea`, `HealthBar3D`, `VisibleOnScreenNotifier3D`.
- **`ui_hud.tscn`** — Virtueller Joystick (links), Kamera-Drag (rechts),
  Skill-Hotbar (unten, 6 Slots mit Cooldown-Overlay), Aktions-Buttons
  (Aktion/Sprung/Sprint), Vitals (HP/Mana/XP), Gold, Minimap (prozedural gezeichnet),
  Quest-Tracker, Toasts, Damage Numbers, Journal/Inventar/Dialog/Tutorial.

---

## 4. Performance & Mobile-Optimierungen (bereits integriert)

- **Mobile-Renderer (Vulkan Mobile)** + per-Plattform Overrides (`.mobile`) in
  `project.godot` (kleinere Shadow-Atlanten, MSAA aus, kein SSAO/SDFGI).
- **ETC2/ASTC Texturkompression** aktiviert (`import_etc2_astc=true`).
- **60-FPS-Cap** (`Engine.max_fps`) + 60-Hz-Physik-Tick → Batterie- und Wärme-schonend.
- **Object-Pooling** für Projektile, Gegner, Loot, Hit-FX (`PoolManager`,
  `prewarm()`) → keine GC-Spikes.
- **MultiMesh** für Vegetation → hunderte Bäume in **1 Draw Call**.
- **`VisibleOnScreenNotifier3D`** drosselt KI-Physik nicht sichtbarer, untätiger Gegner.
- **Spawner-Aktivierung nach Distanz** — Spawner arbeiten nur nahe dem Spieler.
- **CPUParticles3D** statt GPUParticles für Treffer-Effekte (mobil günstiger).
- **Prozedurale Minimap** (via `_draw`) statt zweiter Render-Kamera.
- **Schatten**: nur Sonne, mobil auf 1024er-Atlas reduziert, max. Distanz 80 m.
- **SpringArm3D**-Kamera verhindert teure Re-Renders durch Clipping.

---

## 5. Asset-Empfehlungen

Der Prototyp braucht **keine** Assets zum Start. Zum Aufhübschen:

- **Kenney** (CC0, ideal): Nature Kit, Fantasy Town Kit, UI Pack, Game Icons,
  Audio — <https://kenney.nl/assets>
- **Quaternius** (CC0): Low-Poly Charaktere & Natur — <https://quaternius.com>
- **Poly Pizza**: Low-Poly Modelle — <https://poly.pizza>
- **OpenGameArt** / **freesound.org**: SFX & Musik.

Details & exakte Dateinamen: `assets/audio/README.md` und `assets/textures/README.md`.
Icons können `SkillData.icon` / `ItemData.icon` zugewiesen werden (in `database.gd`
oder via echte `.tres` in `resources/`).

---

## 6. Nächste Erweiterungsschritte

1. **Weitere Gebiete**: `world.tscn` duplizieren, per Portal/Ladezone verbinden;
   `World.player_spawn` je Zone. Streaming über mehrere Szenen.
2. **Mehr Klassen** (Rogue, Priest): neue `ClassData` + `SkillData` in `database.gd`
   (oder `.tres`). System ist datengetrieben — kein Code-Umbau nötig.
3. **Echter Skill-Baum-UI** mit Talentpunkten (Basis in `ClassData.skill_unlocks`).
4. **Charakter-Animationen** (AnimationTree/State-Machine) für importierte Modelle.
5. **Vendor/Shop-NPCs** (Gold ist bereits vorhanden).
6. **Save-Slots & Verschlüsselung** (`FileAccess.open_encrypted_with_pass`).
7. **Controller-Support** zusätzlich zu Touch.
8. **Balancing** über echte `.tres`-Resources statt Code-Defaults.

---

## Checkliste nach dem Kopieren

Siehe **`docs/SETUP.md`** für die vollständige Schritt-für-Schritt-Checkliste
(Godot-Import, optionale Assets, **Android-Export-Setup**, Signierung, Reimport).
