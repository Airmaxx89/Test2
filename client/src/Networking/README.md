# Networking-Modul

Kapselt die gesamte Nakama-Anbindung: Authentifizierung, Session, Realtime-Socket,
Match-Handling sowie Replikation (Snapshot-Interpolation, Client-Prediction,
Server-Reconciliation). Darf nur von `Core` abhängen.

**Kapselungsregel (ADR-0002):** Nakama-SDK-Typen erscheinen ausschließlich innerhalb
dieses Moduls. Der Rest des Clients spricht mit einem stabilen `INetworkService`-Vertrag,
damit ein Backend-Wechsel lokal bliebe.

## Aktueller Stand (Milestone 3, Teil 1)

SDK-freies Fundament vorhanden und CI-getestet:

- `INetworkService` — stabiler, SDK-freier Vertrag (Auth, Verbindung, Sitzung).
- `Connection/ConnectionStateMachine` — validierte Verbindungs-Zustandsübergänge.
- `Connection/ReconnectBackoff` — exponentielles Backoff mit Jitter (Zufall injizierbar).
- `Model/NetworkModels` — `ServerEndpoint`, `AuthCredentials`, `SessionInfo` (kein Nakama-Typ).
- `NetworkEvents` — Zustands-/Auth-/Fehler-Ereignisse für den EventBus (ohne Token).
- `OfflineNetworkService` — SDK-freier Stand-in, im `GameBootstrap` registriert; macht die
  Abstraktion sofort nutzbar und dient als Vorlage.

## Aktueller Stand (Milestone 3, Teil 2)

- `Nakama/NakamaNetworkService` — konkreter Adapter (NuGet `NakamaClient`): Geräte-Auth,
  Session, Realtime-Socket, automatischer Wiederaufbau über `ReconnectBackoff`. Nakama-Typen
  erscheinen ausschließlich in diesem Ordner (ADR-0002). Kompilierung ist CI-verifiziert
  (Job „Client kompilieren").
- `Replication/SnapshotBuffer` — Snapshot-Interpolation „in der Vergangenheit" für entfernte
  Entitäten: sortiert verspätete Pakete ein, klemmt statt zu extrapolieren. CI-getestet.
- `Replication/PredictionReconciler` — Client-Prediction + Server-Reconciliation für die
  eigene Figur: Eingaben sofort anwenden, puffern, nach Server-Ack ab autoritativer Position
  neu abspielen. Bewegungsformel injizierbar (Client/Server teilen dieselbe). CI-getestet.

## Umschalten auf den Nakama-Adapter

Der `GameBootstrap` registriert derzeit den `OfflineNetworkService`. Sobald der lokale
Docker-Stack läuft (`server/README.md`), im Bootstrap ersetzen durch:

```csharp
var endpoint = new ServerEndpoint(
    Config.NakamaUseSsl ? "https" : "http",
    Config.NakamaHost, Config.NakamaPort, Config.NakamaServerKey);
var nakama = new NakamaNetworkService(endpoint, Events, Logger);
Services.Register<INetworkService>(nakama);
Services.Register<IMatchClient>(nakama); // Match-Fähigkeit derselben Instanz
```

Danach die Splash-Zielszene auf `res://scenes/NetPlayground.tscn` stellen (Export
`NextScenePath` am `SplashController` oder direkt die Szene starten). Zwei parallel
gestartete Clients sehen sich gegenseitig als interpolierte Avatare.

## Offene Punkte (Milestone-3-Abnahme)

- Adapter zur Laufzeit gegen den lokalen Docker-Stack verifizieren (Login sichtbar in der
  Nakama-Console) — erfordert lokale Godot-/.NET-Umgebung.
- Godot-Anbindung der Replikation (Senden der Eingaben, Empfangen der Snapshots) auf Basis
  eines autoritativen Match-Handlers in `server/modules/`.
