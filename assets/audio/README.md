# Audio-Assets (Platzhalter)

Der `AudioManager` laedt diese Dateien **defensiv**: Fehlt eine Datei, passiert
nichts (kein Crash). Du kannst das Spiel also sofort ohne Audio starten und die
Sounds spaeter nachliefern. Lege die Dateien exakt unter diesen Namen ab:

## Soundeffekte (`assets/audio/`)
| Datei | Auslöser |
|-------|----------|
| `sfx_hit.ogg` | Auto-Attack-Treffer |
| `sfx_swing.ogg` | Nahkampf-Skill |
| `sfx_aoe.ogg` | Flächen-Skill |
| `sfx_cast.ogg` | Projektil-Zauber |
| `sfx_heal.ogg` | Heilung |
| `sfx_drink.ogg` | Trank benutzen |
| `sfx_equip.ogg` | Ausrüsten |
| `sfx_pickup.ogg` | Loot aufsammeln |
| `sfx_levelup.ogg` | Stufenaufstieg |
| `sfx_player_hurt.ogg` | Spieler nimmt Schaden |
| `sfx_enemy_melee.ogg` | Gegner-Nahangriff |
| `sfx_enemy_shoot.ogg` | Gegner-Fernangriff |
| `sfx_enemy_death.ogg` | Gegner stirbt |

## Musik
| Datei | Verwendung |
|-------|------------|
| `music_forest_ambient.ogg` | Ambient-Loop im Gebiet (loopen aktivieren!) |

## Empfohlene kostenlose Quellen
- **Kenney Audio** (CC0): https://kenney.nl/assets?q=audio
- **OpenGameArt** (diverse Lizenzen): https://opengameart.org
- **freesound.org** (CC): https://freesound.org

## Import-Tipp (Godot)
- OGG Vorbis statt WAV verwenden (kleiner, ideal für Mobile).
- Für Musik im Import-Dock **Loop** aktivieren.
- Optional eigene Audio-Busse `Master > Music`, `Master > SFX` anlegen
  (`AudioManager` nutzt sie automatisch, sonst Fallback auf `Master`).
