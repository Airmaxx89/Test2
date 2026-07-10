# Aethermoor — Entwicklungs-Roadmap

> Iterativer Plan. Es wird **nie** an mehreren großen Systemen gleichzeitig gearbeitet.
> Jede Iteration: analysieren → planen → Risiken → implementieren → testen → optimieren →
> dokumentieren → nächsten Schritt vorschlagen.

Legende: ✅ fertig · 🔄 in Arbeit · ⬜ offen

---

## Milestone 0 — Fundament & Pre-Production  🔄
Ziel: Tragfähige, dokumentierte Basis, auf der 50 Entwickler bauen könnten.

- ✅ Game Design Bible (`docs/GAME_DESIGN.md`)
- ✅ Technische Architektur (`docs/ARCHITECTURE.md`)
- ✅ Coding Standards (`docs/CODING_STANDARDS.md`)
- ✅ ADRs: Engine (Godot 4) & Backend (Nakama)
- ✅ Godot-4-C#-Projektscaffold (`project.godot`, `.csproj`, Ordnerstruktur)
- ✅ Kern-Layer: `GameBootstrap`, `ServiceLocator`, `EventBus`, `GameLogger`
- ⬜ Godot-Editor-Erstimport lokal verifizieren (generiert `.sln`/`.godot`)
- ⬜ CI: `dotnet build` + Analyzer-Gate

## Milestone 1 — Client-Kern lauffähig  ⬜
Ziel: Der Client startet, bootet sauber, zeigt eine Testszene, loggt strukturiert.

- ⬜ Bootstrap-Szene + Splash/Loading-Flow
- ⬜ Konfigurations-Resource + Laden im Bootstrap
- ⬜ Object-Pool-Basis (`Core`) + Unit-Tests
- ⬜ Erste Unit-Test-Suite in CI grün

## Milestone 2 — Mobile-Steuerung & Kamera  ⬜
Ziel: Sich anfühlen wie ein Mobile-Spiel, noch ohne Netzwerk.

- ⬜ Virtueller Joystick (Multi-Touch, konfigurierbar)
- ⬜ Charakter-Controller (lokal) + Kamera (Daumen-Ergonomie)
- ⬜ Auto-Laufen, Smart-Targeting-Grundlage

## Milestone 3 — Netzwerk-Fundament (Nakama)  ⬜
Ziel: Serverautoritatives Grundgerüst.

- ⬜ Lokaler Nakama-Stack (Docker-Compose) in `server/`
- ⬜ Auth + Session + Socket im `Networking`-Modul
- ⬜ Bewegungsreplikation: Prediction + Reconciliation (2 Clients synchron)

## Milestone 4 — Gameplay-Vertikale (eine Klasse, eine Zone)  ⬜
Ziel: Eine durchgängige, echte Spielschleife als Referenzimplementierung.

- ⬜ Datengetriebenes Fähigkeitssystem (`AbilityResource`)
- ⬜ Wächter-Klasse (1 Spec) mit 5 Fähigkeiten
- ⬜ Server-validierte Kampfauflösung (Cooldown/Reichweite/Schaden)
- ⬜ Zone „Morgenau" (Streaming, Spawns, 1 Quest)
- ⬜ Gegner-KI: Aggro/Patrouille/Heimkehr

## Milestone 5+ — Content-Skalierung  ⬜
Weitere Klassen, Zonen, Berufe, Dungeon, Auktionshaus, Gilden — jeweils als eigene
Iteration, ermöglicht durch das datengetriebene Fundament.

---

## Nächster empfohlener Schritt
**Milestone 0 abschließen:** Scaffold lokal in Godot 4 (.NET) importieren, damit die
`.sln`/`.godot`-Artefakte generiert werden, danach CI-Build-Gate einrichten. Anschließend
Milestone 1 (Bootstrap-Szene + Object-Pool + erste Tests) starten.
