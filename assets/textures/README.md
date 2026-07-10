# Textur- & Modell-Assets (Platzhalter)

Der Prototyp laeuft komplett mit **prozeduralen Platzhalter-Meshes**
(Kapseln = Figuren, Kegel = Baeume, Boxen = Ruinen) und eingefaerbten Materialien.
Es sind **keine** Texturen noetig, um zu starten.

## Wenn du echte Assets einbindest

### Empfohlene kostenlose Packs (CC0 / frei)
- **Kenney** – 3D & UI: https://kenney.nl/assets
  - "Nature Kit", "Fantasy Town Kit", "UI Pack", "Game Icons"
- **Quaternius** – Low-Poly Charaktere/Natur: https://quaternius.com
- **OpenGameArt**: https://opengameart.org
- **Poly Pizza** (Low-Poly Modelle): https://poly.pizza

### Skill-/Item-Icons
- Weise Texturen den `SkillData.icon` / `ItemData.icon` Feldern zu
  (in `scripts/autoload/database.gd` oder via echten `.tres` in `resources/`).
- Die Hotbar-Buttons zeigen dann Icons statt Kürzel-Text.

## Mobile-Import-Einstellungen (wichtig für Performance)
1. **Projekt > Projekteinstellungen > Rendering > Texturen**
   - `VRAM Compression: Import ETC2/ASTC` = **an** (bereits gesetzt).
2. Pro Textur im **Import-Dock**:
   - Modus **VRAM Compressed** für 3D-Texturen (nutzt ETC2/ASTC auf Android).
   - **Mipmaps generieren** für 3D-Objekte (weniger Flimmern/Bandbreite).
   - UI-Sprites: **Lossless** oder **VRAM** je nach Bedarf.
3. Nach Änderungen **"Reimport"** klicken (oder Godot neu starten).
4. Für viele gleiche Objekte (Baeume/Gras) den vorhandenen
   `MultiMeshScatter` nutzen (1 Draw Call) statt einzelner Instanzen.
