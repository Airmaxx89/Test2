# Setup- & Export-Checkliste

## A. Projekt zum Laufen bringen (2 Minuten)

- [ ] **Godot 4.3+** installieren (Standard-Build): <https://godotengine.org/download>
- [ ] Godot starten → **Import** → `project.godot` wählen → **Import & Edit**.
- [ ] Erststart abwarten (Godot legt `.godot/` an und importiert Assets/Icon).
- [ ] **F5** drücken. Es startet die Szene `res://scenes/main/main.tscn`.
- [ ] Im Hauptmenü **Neues Spiel** → Name + Klasse (Krieger/Magier) → **Abenteuer beginnen**.
- [ ] Das On-Screen-**Tutorial** erklärt die Touch-Controls (nur beim ersten Mal).

> Läuft sofort mit Platzhalter-Grafik. Kein Asset-Download nötig.

### Steuerung
| Aktion | Touch (Android) | Desktop-Test |
|--------|-----------------|--------------|
| Bewegen | Virtueller Joystick (linke Hälfte) | WASD |
| Kamera drehen | Wischen (rechte Hälfte) | Rechte Maustaste |
| Zoom | Zwei-Finger-Pinch | Mausrad |
| Skills | Hotbar-Buttons (unten) | — |
| Aktion/Sprung/Sprint | Buttons (unten rechts) | E / Leertaste / Shift |
| Journal / Inventar | Buttons (oben rechts) | J / I |
| Auto-Angriff | automatisch bei Zielen in Reichweite | — |

---

## B. Optionale Assets einbinden

- [ ] Audio nach `assets/audio/` legen (Dateinamen siehe `assets/audio/README.md`).
      Für Musik im Import-Dock **Loop** aktivieren.
- [ ] Optional Audio-Busse `Master → Music` und `Master → SFX` anlegen
      (**Audio**-Tab unten). `AudioManager` nutzt sie automatisch.
- [ ] Modelle/Texturen nach `assets/models` / `assets/textures`.
      Pro Textur: Import-Modus **VRAM Compressed** + **Mipmaps** → **Reimport**.
- [ ] Skill-/Item-Icons in `database.gd` (`SkillData.icon` / `ItemData.icon`) zuweisen
      oder echte `.tres` in `resources/…` ablegen (überschreiben Code-Defaults automatisch).

---

## C. Android-Export einrichten

### C.1 Voraussetzungen (einmalig)
- [ ] **Android Export-Templates** installieren:
      Godot → **Editor → Verwalte Export-Templates → Herunterladen & Installieren**.
- [ ] **OpenJDK 17** installieren.
- [ ] **Android SDK** (via Android Studio oder Command-line-Tools), inkl.
      *Platform-Tools* und *Build-Tools*.
- [ ] In Godot: **Editor → Editor-Einstellungen → Export → Android**:
      - `Java SDK Path`, `Android SDK Path` setzen.
      - `Debug Keystore` wird i. d. R. automatisch erzeugt.

### C.2 Debug-Keystore (für Test-APKs)
```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey \
  -keypass android -keystore debug.keystore -storepass android \
  -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```
- [ ] Pfad in **Editor-Einstellungen → Export → Android → Debug Keystore** eintragen.

### C.3 Exportieren
- [ ] **Projekt → Exportieren…** — das Preset **„Android"** ist bereits konfiguriert
      (`export_presets.cfg`): `arm64-v8a`, immersiver Vollbild-Modus, kein Internet.
- [ ] **Export Project** → Ziel `export/aetheria.apk`.
- [ ] Auf Gerät installieren:
```bash
adb install -r export/aetheria.apk
```
- [ ] Alternativ **One-Click-Deploy**: Gerät per USB (USB-Debugging an) → oben rechts
      das Android-Icon → direkt aufs Gerät starten.

### C.4 Release-Build (Play Store)
- [ ] Eigenen **Release-Keystore** erzeugen und in einem *Release*-Preset hinterlegen.
- [ ] Für den Play Store `gradle_build/use_gradle_build = true` und Export als **.aab**.
- [ ] `version/code` und `version/name` in `export_presets.cfg` bei jedem Release erhöhen.

---

## D. Performance-Verifikation auf dem Gerät

- [ ] **Debug → FPS anzeigen** oder `Performance.get_monitor(...)` prüfen — Ziel: stabile 60.
- [ ] Bei Einbrüchen: Schatten-Distanz (`DirectionalLight3D.max_distance`) senken,
      `MultiMeshScatter.instance_count` reduzieren, Spawner-`max_alive` verringern.
- [ ] `project.godot` → `rendering/.../*.mobile`-Overrides ggf. weiter verkleinern.

---

## E. Bekannte Prototyp-Vereinfachungen

- Platzhalter-Meshes statt Charakter-Modellen (bewusst — sofort lauffähig).
- Keine Charakter-Animationen (Modelle drehen sich nur in Bewegungsrichtung).
- Respawn beim Tod am Dorf (kein Heal-over-time out of combat außer beim Level-Up/Leash).
- Ein Save-Slot (`user://savegame.json`), unverschlüsselt (Debug-freundlich).
