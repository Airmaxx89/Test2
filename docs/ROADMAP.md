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
- ✅ Auto-Laufen (`AutoRunController`): einrasten, lenken, Gegensteuern bricht ab — getestet;
  UI-Button in der `Playground`-Szene
- ✅ Smart-Targeting-Grundlage (`SmartTargetSelector`): Reichweite, Blickkegel, Nähe/
  Ausrichtungs-Gewichtung — getestet (Godot-Anbindung folgt mit dem Gegner-Milestone)
- ⬜ Steuerung lokal im Godot-Editor verifizieren (Joystick + Auto-Lauf bewegen Charakter,
  Kamera folgt)

## Milestone 3 — Netzwerk-Fundament (Nakama)  🔄
Ziel: Serverautoritatives Grundgerüst.

- ✅ Lokaler Nakama-Stack (Docker-Compose) in `server/` (aus M0)
- ✅ SDK-freie Abstraktion `INetworkService` (kapselt Nakama, ADR-0002)
- ✅ `ConnectionStateMachine` — validierte Verbindungsübergänge — Unit-getestet
- ✅ `ReconnectBackoff` — exponentiell + Jitter (Thundering-Herd-Schutz) — Unit-getestet
- ✅ Domänenmodelle (`ServerEndpoint`, `AuthCredentials`, `SessionInfo`) + Netz-Events
- ✅ `OfflineNetworkService` (SDK-freier Stand-in) im Bootstrap registriert — Unit-getestet
- ✅ `NakamaNetworkService`: Adapter (Geräte-Auth + Session + Socket + Auto-Reconnect);
  Kompilierung CI-verifiziert (neuer Job „Client kompilieren")
- ✅ Replikations-Mathematik (Godot-frei, Unit-getestet): `SnapshotBuffer`
  (Interpolation, keine Extrapolation) + `PredictionReconciler` (Prediction/Reconciliation)
- ✅ Autoritativer Match-Handler (`server/modules/`, TypeScript-Runtime): Eingaben mit
  Sequenznummern, serverseitige Integration mit der Client-Formel, Tick-Snapshots mit Ack;
  Anti-Cheat-Grundlagen (Richtungs-/Zeit-Klemmung, Replay-Schutz, Rate-Limit).
  Lokal gebaut (`tsc`, strikt) + eigener CI-Job
- ✅ Godot-Anbindung der Replikation: `IMatchClient`-Vertrag (Match-Join per RPC,
  Eingabeversand, thread-sicherer Snapshot-Abruf), SDK-freies Protokollmodul
  (`MovementProtocol`, CI-getestet gegen das Server-Format) und `ReplicatedWorld`-Szene
  (`NetPlayground.tscn`): eigene Figur per Prediction/Reconcile, fremde interpoliert
- ⬜ End-to-End-Abnahme lokal: Docker-Stack starten, Bootstrap auf Nakama umschalten
  (`client/src/Networking/README.md`), 2 Clients sehen sich synchron

## Milestone 4 — Gameplay-Vertikale (eine Klasse, eine Zone)  ⬜
Ziel: Eine durchgängige, echte Spielschleife als Referenzimplementierung.

- ✅ Datengetriebenes Fähigkeitssystem: engine-freier `AbilityCaster` (Cooldowns,
  Ressourcen, Reichweite; Zeit injiziert → deterministisch getestet) +
  `AbilityResource` (.tres-Datenschicht, neue Fähigkeit = neue Datei);
  erste Wächter-Fähigkeiten als Daten (`assets/abilities/`)
- ✅ Touch-Zauberleiste: `AbilityBar` (Daumen-Bogen unten rechts, Daten über
  Ressourcenpfade) + `AbilityButton` (radiale Cooldown-Anzeige, Ausgrauen);
  Zustands-Ableitung engine-frei (`AbilityStatusResolver`, getestet); Wirk-Ereignisse
  über EventBus (`AbilityCastPredicted/Rejected`)
- ✅ Gegner-Grundlage: engine-freies KI-Gehirn (`EnemyBrain`: Patrouille → Aggro
  [klebrig] → Verfolgen/Angriff → Leine/Heimkehr, getestet) + `HealthPool` (getestet);
  `EnemyResource`-Daten + `EnemyController` (Zustandsfarbe, Lebensbalken, Zielring)
- ✅ Smart-Targeting angebunden: `CombatDirector` wählt Ziel per `SmartTargetSelector`
  (Reichweite + Blickkegel), markiert es und liefert der Zauberleiste die echte
  Zieldistanz (`ITargetDistanceProvider`); Schadens-Fähigkeiten treffen das Ziel
- ✅ Beidseitiger Kampf: Gegner greifen an (`AttackTicker`, Werte aus Daten), Spieler hat
  `HealthPool` + Respawn; „Zweiter Wind" heilt tatsächlich; Kampfzahlen als **gepoolte**
  schwebende Zahlen (`DamageNumberSpawner` nutzt `ObjectPool`); HUD-Lebensbalken
  (event-getrieben, kein Polling)
- ✅ Wächter auf 5 Fähigkeiten + Combo-System: `ComboTracker` (Marker mit Ablauf,
  ein Finisher pro Marker, Ziele unabhängig — getestet); Definition/Resource um
  Combo-Felder erweitert (validiert); Combo-Paar Wappenbruch → Vergeltung (+60 %)
  und Fernoption Schildwurf als Daten; Cast-Event trägt jetzt die volle Definition
- ✅ Zone „Morgenau" + Spawn-System: `ZoneController`/`SpawnPoint` (Zonen sind
  Szenen-Daten; Respawns über getesteten `RespawnScheduler`); Gegner-Tode als
  `EnemyDefeatedEvent` über den EventBus
- ✅ Erste Quest: engine-freier `QuestTracker` (getestet) + `QuestResource`-Daten,
  `QuestDirector` + Quest-HUD; „Plage am Wegesrand" (3 Wegelagerer) in Morgenau;
  Splash-Ziel ist jetzt Morgenau
- ✅ Charakter-Progression: engine-freier `ExperienceTracker` (parametrische Kurve,
  Überlauf über Level-Grenzen, Cap verwirft — getestet); XP aus Gegner-Toden und
  Quest-Abschluss (Werte in den Daten); `ProgressionDirector` (EventBus-Quellen,
  Open/Closed) + XP-Leiste im HUD
- ⬜ Vertikale lokal im Editor verifizieren (Quest zählt + gibt 150 XP, Kills je 25 XP,
  Level-Up im Log, Respawn nach 20 s, Combo-Bonus, Heilung, Spieler-Respawn)
- ⬜ Server-validierte Kampfauflösung (Cooldown/Reichweite/Schaden)
- ⬜ Zone „Morgenau" (Streaming, Spawns, 1 Quest)
- ⬜ Gegner-KI: Aggro/Patrouille/Heimkehr

## Milestone 5 — Serverautoritativer Kampf  🔄
Ziel: Der Server führt den Kampf verbindlich; der Client sagt nur voraus (ADR-0002).

- ✅ Autoritative Kampf-Daten serverseitig (`combat_data.ts`: 5 Wächter-Fähigkeiten,
  Gegnertypen, Zonen-Spawnliste) — erste echte Instanz von „Balancing lebt am Server"
- ✅ Wirk-Validierung im Match-Handler (OpCodes 3/4): Cooldown, Ressource, Ziel,
  Reichweite (+ Latenz-Toleranz); autoritative Schadens-/Combo-/Heil-/XP-Auflösung;
  Gegner-Leben + Respawns servergeführt; erweiterte Snapshots (hp/res/xp + enemies)
- ✅ Client-Anbindung (Transport + Feedback): Cast-Protokoll (OpCodes 3/4) SDK-frei &
  getestet (Feldnamen gegen Server-Format); `IMatchClient` um `SendCastRequest`/
  `TryDequeueCastResult` erweitert (gleiche thread-sichere Queue wie Snapshots);
  `CombatDirector` sendet Casts (predict-and-confirm) und macht Server-Ablehnungen als
  `AbilityCastRejectedEvent` sichtbar; Gegner tragen Server-Spawn-ID
- ⬜ Autoritative Übernahme von Gegner-Leben/-Tod aus Snapshots (löst lokale
  Schadensvorhersage ab; ermöglicht sauberen Rollback)
- ⬜ Server-KI: Gegnerbewegung/-angriffe in den Match-Handler heben (Client-KI wird
  reine Darstellung)
- ⬜ Gemeinsame Daten-Quelle für Client-.tres und `combat_data.ts` (generiert)

## Milestone 5+ — Content-Skalierung  ⬜
Weitere Klassen, Zonen, Berufe, Dungeon, Auktionshaus, Gilden — jeweils als eigene
Iteration, ermöglicht durch das datengetriebene Fundament.

---

## Nächster empfohlener Schritt
**Milestone 0 abschließen:** Scaffold lokal in Godot 4 (.NET) importieren, damit die
`.sln`/`.godot`-Artefakte generiert werden, danach CI-Build-Gate einrichten. Anschließend
Milestone 1 (Bootstrap-Szene + Object-Pool + erste Tests) starten.
