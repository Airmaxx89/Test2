# Nordmark Legends

Ein eigenständiges, komplett offline spielbares Mittelalter-RPG im blockigen
Voxel-Look (Minecraft-artige Optik), inspiriert von klassischen MMORPGs wie
World of Warcraft in Spielgefühl und Struktur (Charaktererstellung, Quests,
Level 1-20, Klassenfähigkeiten, Startgebiete) — jedoch **keine Kopie**.

## Wichtiger rechtlicher Hinweis

Dieses Projekt ist **keine 1:1-Kopie von World of Warcraft** und darf das aus
urheberrechtlichen Gründen auch nicht sein. Alles in diesem Repository ist
eigenständig erstellt:

- **Namen & Lore**: Eigene Welt "Königreich Eichenmark" mit eigenen Orten
  (Eichenfeld, Wolfsschlucht, Steinbrück, Rabenmoor, Grimmwacht), eigenen
  NPCs und einer eigenen Questkette. Keine Verwendung von Begriffen wie
  "World of Warcraft", "Azeroth", "Stormwind", "Horde/Allianz" usw.
- **Rassen/Klassen**: Mensch/Zwerg/Waldelf und Krieger/Magier/Jäger sind
  generische Fantasy-Archetypen, die in unzähligen Rollenspielen (auch lange
  vor WoW) vorkommen, keine WoW-exklusiven Konzepte (z. B. keine
  "Nachtelfen", "Draenei", "Tauren" etc.).
- **Monster**: Wolf, Wildschwein, Kobold, Wegelagerer, Riesenspinne, Skelett
  sind klassische, generische Fantasy-/Sagengestalten (Kobolde sind sogar
  originär deutsche Folklore, älter als jedes Videospiel).
- **Grafik**: Sämtliche Texturen und Icons werden von einem eigenen
  Python-Skript (`tools/generate_textures.py`) prozedural erzeugt - keine
  Blizzard-Assets, keine fremden Texturen, keine Minecraft-Dateien.
- **Code**: Komplett neu geschriebenes GDScript für Godot 4, keine
  dekompilierten oder kopierten Spieldateien.

Kurz: Gleiches *Genre* und *Spielgefühl* (mittelalterliches Offline-RPG mit
Leveling und Quests), aber eigenständiges Werk.

## Über das Spiel

- **Engine**: Godot 4.2+ (GDScript), Ziel-Plattform Android (offline, keine
  Netzwerk-Berechtigung im Export)
- **Optik**: 3D-Voxelwelt im Minecraft-Stil, prozedural generiertes Terrain
- **Setting**: Königreich Eichenmark, ein mittelalterlich-deutsch anmutendes
  Startgebiet, das einen Charakter von Level 1 auf Level 20 bringt
- **Zonen** (in Reisereihenfolge): Eichenfeld (Dorf) → Wolfsschlucht (Wald) →
  Steinbrück (Stadt & Minen) → Rabenmoor (Sumpf) → Grimmwacht (Festungsruine)
- **Charaktererstellung**: 3 Völker × 3 Klassen (Krieger/Magier/Jäger), jede
  Klasse mit 3 Fähigkeiten (freigeschaltet auf Stufe 1/5/10)
- **Quests**: 22 zusammenhängende Quests, die Spieler von Level 1 bis 20
  führen (Kill-, Sammel- und Erkundungsquests)
- **Speichern**: Vollständig lokal (JSON-Datei im App-Datenverzeichnis),
  keine Internetverbindung nötig oder angefordert

## Projektstruktur

```
project.godot            Godot-Projektdatei (Autoloads, Rendering, Physik)
export_presets.cfg        Android-Exportvorlage
default_env.tres          Standard-3D-Umgebung (Himmel, Nebel, Licht)
icon.svg                  App-/Editor-Icon (eigenes Design)

autoload/                 Singletons: GameManager, QuestManager, SaveManager,
                           InputState (Touch-UI-Bridge), DialogueState
data/                     Reine Datendefinitionen (Rassen, Klassen, Items,
                           Monster, Quests, Zonen, Voxel-Blocktypen)
scripts/world/            World.gd (Terraingenerierung, Chunk-Streaming,
                           Spawner), Chunk.gd (Mesh-Erzeugung)
scripts/entities/         Player.gd, Mob.gd, NPC.gd, CharacterModel.gd
                           (blockiges Figuren-Modell aus Primitiven)
scripts/ui/                HUD, Touch-Steuerung, Charaktererstellung,
                           Inventar, Questlog, Dialog, Startmenü
scripts/main/Main.gd       Spielfluss: Startmenü → (Charaktererstellung) →
                           Welt + UI

tools/generate_textures.py  Erzeugt assets/textures/atlas.png (Blocktexturen)
                             und assets/textures/icons/*.png (Item-Icons)
assets/textures/            Generierte Pixel-Art-Texturen (siehe oben)
```

## Öffnen & Testen (Godot Editor)

1. [Godot 4.2 oder neuer](https://godotengine.org/download) installieren.
2. Projekt öffnen: Godot starten → "Import" → `project.godot` in diesem
   Repo auswählen.
3. Play-Button drücken. Die Steuerung funktioniert im Editor über die Maus
   (linke Bildschirmhälfte klicken+ziehen = Bewegung, rechte Hälfte
   klicken+ziehen = Kamera), da `emulate_touch_from_mouse` aktiviert ist.

**Hinweis:** Die Texturen in `assets/textures/` sind bereits generiert und
eingecheckt. Falls du sie neu erzeugen willst (z. B. nach Änderungen am
Skript): `python3 tools/generate_textures.py` (benötigt `pillow`,
`pip install pillow`).

## Als Android-APK exportieren

1. In Godot: **Editor → Manage Export Templates** → passende Export-Templates
   für deine Godot-Version herunterladen.
2. Android-SDK/-NDK gemäß der [offiziellen Godot-Android-Anleitung](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
   einrichten (Android Studio Command Line Tools, Java/Keystore).
3. **Project → Export...** → Preset "Android" (bereits in
   `export_presets.cfg` vorbereitet, inkl. Debug-Keystore) → **Export
   Project** → erzeugt eine `.apk`, die direkt auf ein Android-Gerät
   installiert werden kann (Entwickleroptionen → USB-Debugging, oder Datei
   manuell kopieren und installieren).
4. Die App fordert **keine Internetberechtigung** an - sie ist bewusst rein
   offline.

## Bekannte Grenzen dieser ersten Version

Diese Version wurde ohne Zugriff auf einen laufenden Godot-Editor/Emulator
erstellt (reine Code-Entwicklung). Bitte nach dem ersten Öffnen im Editor
prüfen:

- Balancing (Schaden, XP-Kurve, Mob-Dichte) ist ein erster Wurf und sollte
  im echten Spieltest justiert werden.
- Die UI ist bewusst schlicht (Godot-Standard-Controls) gehalten - Prioriät
  lag auf funktionierenden Systemen statt auf Feinschliff der Optik.
- Landschaft/Gebäude sind einfache, funktionale Voxel-Strukturen (Fachwerk-
  Dörfer, Festungsmauern) - Details wie Fenster, Möbel, mehr Gebäudevielfalt
  lassen sich leicht per `World.gd`-Overrides ergänzen.
- Kein Crafting, keine Ausrüstungsslots über die Waffe hinaus, kein Handel
  mit NPCs (Gold wird gesammelt, aber es gibt noch keinen Händler-NPC) -
  bewusst für den MVP-Umfang weggelassen.

## Roadmap (nächste Schritte)

1. **Playtesting & Balancing** im echten Editor/Gerät.
2. **Mehr Inhalt in Eichenmark**: weitere Nebenquests, Händler-NPCs,
   Ausrüstungs-Upgrades, mehr Gebäudevielfalt.
3. **Neue Gebiete** (wie ursprünglich gewünscht: Nachbarländer): das
   `ZoneData.gd`-Schema ist bewusst so gebaut, dass sich neue Zonen, NPCs,
   Spawner und Quest-Ketten einfach anhängen lassen, ohne bestehenden Code
   zu verändern - Level 20+ Erweiterungsgebiete sind der nächste logische
   Schritt.
4. **Persistenz-Erweiterung**: Erfolge, mehrere Speicherstände,
   Charakterauswahl-Bildschirm.
