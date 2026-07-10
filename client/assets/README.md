# Assets

Kunst, Audio und Shader. Verbindliche Mobile-Optimierung (siehe docs/ARCHITECTURE.md §6):

- Texturen: ETC2/ASTC-komprimiert, wo möglich als **Atlas** (weniger Draw Calls).
- Vegetation/Props: für **MultiMesh-Instancing** vorbereiten.
- Audio: Musik als komprimierter Stream, SFX als kurze, poolbare One-Shots.

Geplante Struktur: `art/`, `audio/`, `shaders/`. Große Binärassets werden erst mit den
zugehörigen Milestones eingecheckt, um das Repository schlank zu halten.
