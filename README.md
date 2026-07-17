# Aethermoor — Ein stylisiertes Mobile-MMORPG (Android)

> Ein serverautoritatives, für Smartphones von Grund auf entwickeltes Fantasy-MMORPG.
> Engine: **Godot 4 (C#)** · Backend: **Nakama** · Zielplattform: **ausschließlich Android**.

Dieses Repository ist als langlebige, erweiterbare Codebasis eines AAA-Studios aufgebaut.
Jede Architekturentscheidung ist so getroffen, dass später weitere Kontinente, Klassen,
Berufe, Dungeons, Raids und Events **ohne grundlegende Umbauten** ergänzt werden können.

---

## Projektstruktur

```
.
├── docs/                     # Die "Projekt-Bibel" — verbindliche Referenz über alle Sessions hinweg
│   ├── GAME_DESIGN.md        # Lore, Welt, Fraktionen, Völker, Klassen, Systeme
│   ├── ARCHITECTURE.md       # Technische Architektur, Stack, Ordnerkonventionen
│   ├── CODING_STANDARDS.md   # Verbindliche Code-Regeln (SOLID, Naming, Tests)
│   ├── ROADMAP.md            # Iterativer Entwicklungsplan (Milestones)
│   └── adr/                  # Architecture Decision Records (nachvollziehbare Entscheidungen)
│
├── client/                   # Godot-4-Projekt (C#) — der Spiel-Client
│   ├── project.godot         # Godot-Projektkonfiguration (Mobile-Renderer, Android)
│   ├── Aethermoor.csproj     # .NET-Projekt (Godot.NET.Sdk)
│   ├── src/                  # Sämtlicher C#-Quellcode, modular nach Domäne getrennt
│   │   ├── Core/             # Wiederverwendbarer Kern (EventBus, Services, Logging, Bootstrap)
│   │   ├── Gameplay/         # Kampf, Charakter, Progression, Fähigkeiten
│   │   ├── World/            # Weltstreaming, Gebiete, Wetter, Tag/Nacht
│   │   ├── Networking/       # Nakama-Integration, Synchronisation, Prediction
│   │   └── UI/               # Touch-first Mobile-UI (Joystick, HUD, Menüs)
│   ├── scenes/               # Godot-Szenen (.tscn)
│   └── assets/               # Kunst, Audio, Shader (komprimiert, Atlas-fähig)
│
└── server/                   # Nakama-Backend (autoritative Serverlogik & Custom-RPCs)
```

## Technologie-Stack (Zusammenfassung)

| Schicht        | Technologie            | Begründung (Details in `docs/adr/`)                        |
|----------------|------------------------|------------------------------------------------------------|
| Engine         | Godot 4 (C#)           | Schlank, akkuschonend, Open Source, ideal für Mobile.      |
| Sprache Client | C# (.NET 8)            | Typsicher, teilbare Domänenmodelle, performant.            |
| Backend        | Nakama                 | Serverautoritativ: Auth, Realtime, Matchmaking, Chat, Storage. |
| Serverlogik    | Nakama Runtime (Go/TS) | Autoritative Validierung, Anti-Cheat-Grundlagen.           |
| Zielplattform  | Android                | Einziges Ziel; UI/Steuerung ausschließlich Touch-first.    |

## Entwicklungs-Setup

> Hinweis: Dieser Cloud-Container enthält keine Godot-/.NET-Toolchain. Das Scaffold ist
> so aufgebaut, dass es lokal bzw. in CI mit den unten genannten Versionen geöffnet und
> gebaut wird.

**Voraussetzungen (lokal):**
- Godot 4.4+ **.NET-Version** (Mono/C#-Build)
- .NET SDK 8.0+
- Docker + Docker Compose (für lokales Nakama)

**Client öffnen:**
1. Godot 4 (.NET) starten → `client/project.godot` importieren.
2. Godot generiert `.godot/` beim ersten Import; die `Aethermoor.sln` ist eingecheckt
   (der Editor baut über die Solution und erzeugt sie nicht automatisch).
3. Build via Godot-Editor (Hammer-Symbol) oder `dotnet build client/Aethermoor.csproj`.
4. Schlägt der Editor-Build ohne Details fehl („The build method threw an exception"):
   `dotnet build client/Aethermoor.csproj` im Terminal zeigt die echte Fehlermeldung.

**Backend lokal starten:** siehe `server/README.md`.

## Mitwirken

Verbindliche Regeln in [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md).
Der aktuelle Plan und der jeweils nächste sinnvolle Schritt stehen in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Lizenz

Noch nicht festgelegt. Bis zur Klärung gilt: **All rights reserved** (proprietär).
