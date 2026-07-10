# ADR-0002: Backend — Nakama (serverautoritativ)

- **Status:** Angenommen
- **Datum:** 2026-07-10
- **Entscheider:** Projektleitung (bestätigt durch Auftraggeber)

## Kontext
Das Spiel muss serverautoritativ sein: Login/Accounts, Charaktere, Gruppen, Gilden,
Freunde, Chat, PvP, Instanzen, Matchmaking, Synchronisation und Anti-Cheat-Grundlagen.
Fairness und Wirtschaft dürfen nicht vom Client abhängen. Das Team soll sich auf
Spiellogik konzentrieren statt Basisinfrastruktur neu zu bauen.

## Entscheidung
Als Backend wird **Nakama** (Open Source, Heroic Labs) eingesetzt. Custom-Spiellogik läuft
in der Nakama-Server-Runtime; der Godot-Client nutzt das Nakama-SDK.

## Betrachtete Alternativen
- **Custom C# .NET Server:** Volle Kontrolle, teilbare Domänenmodelle. Nachteil: erheblicher
  Eigenbau von Auth, Realtime, Matchmaking, Chat, Storage, Presence — hohes Risiko und
  Zeitkosten, bevor Gameplay entsteht.
- **Nakama:** Liefert Authentifizierung, Realtime-Multiplayer (autoritative Matches),
  Matchmaker, Chat, Storage, Friends/Groups, Leaderboards out of the box; erweiterbar über
  Custom-RPCs und Match-Handler in Go/TypeScript. Open Source, selbst hostbar.

## Begründung
Nakama deckt praktisch die gesamte in der Design-Bibel geforderte Multiplayer-Feature-Liste
(§12) ab und reduziert das Infrastruktur-Risiko drastisch. Die autoritativen Match-Handler
sind der natürliche Ort für server-validierte Kampf-, Loot- und Handelslogik und damit für
die geforderten Anti-Cheat-Grundlagen.

## Konsequenzen
- **Positiv:** Schneller, robuster Start; bewährte Skalierung; Fokus des Teams auf Gameplay;
  selbst hostbar (Kostenkontrolle), keine Vendor-Sperre auf Datenebene (Postgres).
- **Negativ / Risiken:** Serverseitige Custom-Logik in Go/TS statt C# → zweite Sprache im
  Stack; Domänenmodell-Duplikation zwischen Client (C#) und Server (Go/TS). → Gemildert
  durch **eine einzige Quelle der Wahrheit** für Definitionen (datengetriebene Schemata,
  geteilt/generiert) und eine dünne Client-`Networking`-Schicht, die Nakama kapselt, damit
  ein späterer Wechsel lokal bleibt.
- **Folgeauflagen:**
  - Der Client greift **nie** direkt auf Nakama-Typen außerhalb des `Networking`-Moduls zu
    (Kapselung, Austauschbarkeit).
  - Alle fairness-/wirtschaftsrelevanten Aktionen werden serverseitig validiert
    (Cooldown, Reichweite, Ressourcen, Position, Rate-Limits).
  - Lokale Entwicklung über Docker-Compose (Nakama + Postgres) in `server/`.
