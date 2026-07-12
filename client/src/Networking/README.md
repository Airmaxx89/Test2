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

## Nächste Iteration

- `Nakama/NakamaNetworkService` — konkreter Adapter (NuGet `NakamaClient`), der den Offline-
  Stand-in ersetzt. Wird gegen den lokalen Docker-Stack (`server/`) verifiziert. Nakama-Typen
  erscheinen ausschließlich in diesem Ordner.
- `Replication/` — Snapshot-Interpolation, Client-Prediction, Server-Reconciliation.
