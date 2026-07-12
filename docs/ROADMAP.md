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

## Milestone 1 — Client-Kern lauffähig  🔄
Ziel: Der Client startet, bootet sauber, zeigt eine Testszene, loggt strukturiert.

- ✅ Konfigurations-Resource (`GameConfig`) + Laden im Bootstrap (mit Fallback)
- ✅ Object-Pool-Basis (`Core/Pooling`) — Godot-frei, allokationssparend
- ✅ Unit-Test-Suite (ServiceLocator, EventBus, ObjectPool), Godot-frei in CI lauffähig
- ✅ CI-Workflow (`dotnet test`) auf jeden Push/PR
- ✅ CI grün verifiziert (GitHub Actions Run #1: alle Tests bestanden)
- ✅ `SceneRouter`-Dienst: asynchroner, nicht-blockierender Szenenwechsel (threaded Load)
- ✅ Splash-/Loading-Flow (Bootstrap → MainMenu) mit Fortschrittsbalken über EventBus
- ✅ `SceneLoadTracker` (Godot-frei) mit Unit-Tests — Phasen & monotoner Fortschritt
- ⬜ Splash-/Ladefluss lokal im Godot-Editor verifizieren (Szenenwechsel sichtbar)

## Milestone 2 — Mobile-Steuerung & Kamera  🔄
Ziel: Sich anfühlen wie ein Mobile-Spiel, noch ohne Netzwerk.

- ✅ Virtueller Joystick (dynamisch, Multi-Touch, konfigurierbar) — `VirtualJoystick`
- ✅ Godot-freie Joystick-Mathematik (`VirtualJoystickProcessor`) mit Totzone,
  radialer Klemmung & Remap — Unit-getestet
- ✅ Lokaler Charakter-Controller (`LocalCharacterController`) gegen `IMovementInputSource`
- ✅ Geglättete Folgekamera (`FollowCamera`) mit Godot-freiem, bildratenunabhängigem
  `CameraFollowSolver` — Unit-getestet
- ✅ Interaktive `Playground`-Szene (Joystick → Charakter → Kamera) als Splash-Ziel
- ⬜ Steuerung lokal im Godot-Editor verifizieren (Joystick bewegt Charakter, Kamera folgt)
- ⬜ Auto-Laufen & Smart-Targeting-Grundlage

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
