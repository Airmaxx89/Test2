# Networking-Modul

Kapselt die gesamte Nakama-Anbindung: Authentifizierung, Session, Realtime-Socket,
Match-Handling sowie Replikation (Snapshot-Interpolation, Client-Prediction,
Server-Reconciliation). Darf nur von `Core` abhängen.

**Kapselungsregel (ADR-0002):** Nakama-SDK-Typen erscheinen ausschließlich innerhalb
dieses Moduls. Der Rest des Clients spricht mit einem stabilen `INetworkService`-Vertrag,
damit ein Backend-Wechsel lokal bliebe.

Geplante Unterordner (ab Milestone 3): `Nakama/`, `Replication/`.
