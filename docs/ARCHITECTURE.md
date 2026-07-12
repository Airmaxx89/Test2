# Aethermoor — Technische Architektur

> Verbindliche technische Referenz. Ergänzt die Game Design Bible um das *Wie*.
> Grundsatzentscheidungen sind zusätzlich als ADR in `docs/adr/` dokumentiert.

---

## 1. Stack-Überblick

```
┌─────────────────────────────────────────────────────────────┐
│  CLIENT  (Godot 4, C# / .NET 8)  — Android                   │
│                                                              │
│  UI  ─────────►  Gameplay  ─────────►  World                 │
│   │                 │                    │                   │
│   └──────────►  Core (EventBus, ServiceLocator, Logging) ◄───┘
│                     │                                        │
│                 Networking  ──── Nakama Client SDK ──────────┼──┐
└─────────────────────────────────────────────────────────────┘  │
                                                                  │ WebSocket / RPC
┌─────────────────────────────────────────────────────────────┐  │
│  BACKEND (Nakama)  — serverautoritativ                       │◄─┘
│  Auth · Realtime-Match · Matchmaker · Chat · Storage         │
│  Custom Runtime (Go/TS): Kampf-, Loot-, Handels-Validierung  │
└─────────────────────────────────────────────────────────────┘
```

**Kernprinzip:** Der Client **stellt dar und sagt Absichten voraus**; der Server
**entscheidet und bestätigt**. Kein Spielzustand, der Fairness oder Wirtschaft betrifft,
ist clientautoritativ.

---

## 2. Client-Architektur

### 2.1 Schichten (Abhängigkeitsrichtung: oben → unten, nie umgekehrt)

| Schicht        | Verantwortung                                              | Darf abhängen von |
|----------------|------------------------------------------------------------|-------------------|
| **UI**         | Touch-Eingabe, HUD, Menüs, Darstellung von Zustand         | Gameplay, Core    |
| **Gameplay**   | Kampf, Charakter, Fähigkeiten, Progression, Quests, Replikations-Anbindung | World, Networking (nur SDK-freie Verträge), Core |
| **World**      | Zonen, Streaming, Wetter, Tag/Nacht, Vegetation, Spawns    | Core              |
| **Networking** | Nakama-Anbindung, Replikation, Prediction/Reconciliation   | Core              |
| **Core**       | EventBus, ServiceLocator, Logging, Bootstrap, Utilities    | — (nichts)        |

> **Ergänzung (Milestone 3):** Gameplay darf die **SDK-freien Verträge** des
> Networking-Moduls nutzen (`INetworkService`, `IMatchClient`, Protokoll-/Replikationstypen)
> — in einem MMO ist serverabhängiges Gameplay der Normalfall. Nakama-SDK-Typen bleiben
> weiterhin ausschließlich im Adapter (ADR-0002).

> **Regel:** `Core` kennt keine höhere Schicht. Kommunikation nach oben erfolgt
> **ausschließlich** über den `EventBus` (lose Kopplung), niemals über direkte Referenzen.

### 2.2 Kern-Bausteine (`src/Core/`)

- **`GameBootstrap`** — einziger Einstiegspunkt (Godot-Autoload). Registriert Services in
  fester Reihenfolge, initialisiert Logging, lädt Konfiguration, startet die erste Szene.
  Kein anderer Code führt globale Initialisierung durch.
- **`ServiceLocator`** — schlanke, typsichere Registry für langlebige Dienste
  (`IService`). Ermöglicht Testbarkeit (Mock-Injektion) und entkoppelt Konsumenten von
  konkreten Implementierungen (Dependency-Inversion, SOLID-**D**).
- **`EventBus`** — typisierte Publish/Subscribe-Zentrale (`IGameEvent`). Entkoppelt
  Systeme: z. B. feuert Gameplay `PlayerDamagedEvent`, UI reagiert, ohne dass Gameplay die
  UI kennt (Open/Closed, SOLID-**O**).
- **`GameLogger`** — strukturiertes Logging mit Leveln & Kategorien. Kein `GD.Print`
  verstreut im Code.

### 2.3 Godot-Konventionen
- **Szenen (`.tscn`)** komponieren, **Skripte (`.cs`)** verhalten. Szenen bleiben schlank;
  Logik liegt in testbaren C#-Klassen, nicht in Node-Bäumen.
- **Autoloads** ausschließlich für echte Singletons des Kerns (Bootstrap/Core). Keine
  Gameplay-Singletons als Autoload.
- **Signale vs. EventBus:** Godot-Signale für lokale Node-zu-Node-Kommunikation innerhalb
  einer Szene; `EventBus` für systemübergreifende, entkoppelte Ereignisse.

---

## 3. Ordnerkonvention (`client/src/`)

```
Core/
  Bootstrap/      GameBootstrap.cs
  Events/         EventBus.cs, IGameEvent.cs
  Services/       ServiceLocator.cs, IService.cs
  Diagnostics/    GameLogger.cs, ILogger.cs, LogLevel.cs
Gameplay/
  Combat/         (Kampf-Auflösung clientseitig: nur Darstellung + Prediction)
  Character/      Attribute, Progression, Talente
  Abilities/      Fähigkeiten (datengetrieben)
  Quests/
World/
  Streaming/      Zonen-Streaming, LOD-Steuerung
  Environment/    Wetter, Tag/Nacht
Networking/
  Nakama/         Session, Socket, Match-Handling
  Replication/    Snapshot, Interpolation, Reconciliation
UI/
  Controls/       Virtueller Joystick, Buttons
  HUD/            Minimap, Buff-Leiste, Schadenszahlen
  Screens/        Inventar, Charakter, Karte, Auktionshaus
```

**Ein Ordner = eine Domäne.** Neue Systeme entstehen als neuer Ordner + EventBus-Anbindung,
nicht durch Aufblähen bestehender Klassen.

---

## 4. Datengetriebenes Design

Inhalte (Klassen, Fähigkeiten, Gegner, Zonen, Loot-Tabellen, Rezepte) werden als **Daten**
definiert (Godot `Resource`-`.tres` bzw. serverseitige Definitionen), **nicht** hartcodiert.
Das erfüllt die Anforderung, neue Klassen/Berufe/Dungeons „ohne grundlegende Umbauten"
zu ergänzen:

- Eine neue Fähigkeit = neue `AbilityResource`, kein Codeeingriff am Kampfsystem.
- Ein neuer Gegner = neue `EnemyDefinition` + Behaviour-Tree-Zuordnung.
- Eine neue Zone = neues Weltmodul mit eigenem Streaming-Manifest.

Balancing-relevante Werte liegen **serverseitig** und werden clientseitig nur gespiegelt.

---

## 5. Netzwerk- & Autoritätsmodell

- **Transport:** Nakama Realtime (WebSocket) für Bewegung/Kampf; RPC für Transaktionen
  (Handel, Auktion, Craft).
- **Autorität:** Server validiert jede Aktion (Cooldown, Reichweite, Ressourcen, Position).
- **Prediction:** Client sagt eigene Bewegung/Fähigkeit voraus; Server-Snapshot korrigiert
  (Reconciliation). Fremde Entitäten werden interpoliert.
- **Anti-Cheat-Grundlagen:** Rate-Limits, Bewegungsplausibilität, serverseitige Cooldowns,
  keine client-gesetzten Schadens-/Loot-Werte. (Details ADR-0002.)

---

## 6. Performance-Architektur (Android-Budget aus GAME_DESIGN §15)

Verbindliche Techniken und wo sie leben:

| Technik              | Ort / Mechanik                                              |
|----------------------|------------------------------------------------------------|
| **LOD**              | `World/Streaming` — Distanz-gestufte Meshes/Impostoren      |
| **Frustum-Culling**  | Godot-nativ; Szenen so aufgebaut, dass Culling greift       |
| **Occlusion-Culling**| Godot Occluder-Instanzen in dichten Zonen (Städte/Höhlen)   |
| **Object Pooling**   | `Core`-Pool für Projektile, Schadenszahlen, VFX, Gegner     |
| **Asset-Streaming**  | Zonen-basiertes Laden/Entladen, asynchron (`ResourceLoader`)|
| **Texture-Atlas**    | UI & Umgebungs-Sets als Atlas → weniger Draw Calls          |
| **Instancing**       | Vegetation/Props via MultiMesh                              |
| **Komprimierte Assets** | ETC2/ASTC-Texturen, komprimierte Audio-Streams          |
| **Renderer**         | Godot **Mobile**-Renderer (Vulkan Mobile), akkuschonend     |

**Prozessregel:** Jedes PR beschreibt in der Beschreibung die Performance-Auswirkung
(Draw Calls / Allokationen / Speicher), sofern es die Renderpfade oder Hot-Loops berührt.

---

## 7. Fehler-, Konfigurations- & Logging-Strategie

- **Logging:** zentral über `GameLogger` mit Kategorien (`Net`, `Combat`, `World`, `UI`)
  und Leveln (`Trace`…`Error`). In Release-Builds werden `Trace`/`Debug` kompiliert-out
  bzw. gefiltert.
- **Konfiguration:** typsichere Konfigurationsobjekte, vom `GameBootstrap` geladen; keine
  verstreuten Magic Numbers (siehe CODING_STANDARDS §Konstanten).
- **Fehler:** Netzwerk-/Ladefehler werden abgefangen, geloggt und dem Spieler nutzerfreundlich
  (Retry-UI) präsentiert — nie stiller Absturz.

---

## 8. Test-Strategie

- **Unit-Tests:** Reine C#-Logik (Schadensformeln, Progression, Inventar) ohne Godot-Abhängigkeit,
  damit sie in CI ohne Editor laufen. Deshalb Logik von Nodes trennen (§2.3).
- **Integrationstests:** Netzwerkpfade gegen lokales Nakama (Docker).
- **Manuelle Geräte-Tests:** Zielgeräte-Matrix (High-End + Mittelklasse Android) pro Milestone.

---

## 9. Build & CI (Zielbild)

- Client: `dotnet build` + Godot-Headless-Export (Android APK/AAB) in CI.
- Backend: Docker-Compose-Stack (Nakama + Postgres) für lokale Entwicklung und Tests.
- Statische Analyse: `.editorconfig`-erzwungene Regeln, Analyzer-Warnungen als Fehler in CI.
