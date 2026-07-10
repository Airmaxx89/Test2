# Aethermoor — Backend (Nakama)

Serverautoritatives Backend (ADR-0002). Nakama liefert Auth, Realtime-Matches,
Matchmaker, Chat, Storage, Friends/Groups. Custom-Spiellogik (Kampf-, Loot-,
Handelsvalidierung) lebt als Match-Handler/RPCs in der Nakama-Runtime.

## Lokale Entwicklung

Voraussetzung: Docker + Docker Compose.

```bash
cd server
docker compose up
```

Danach erreichbar:
- Nakama API/Realtime: `http://127.0.0.1:7350` (Server-Key: `defaultkey`, nur lokal)
- Nakama Console:       `http://127.0.0.1:7351`
- Postgres:             `127.0.0.1:5432`

> **Sicherheit:** Die Werte in `docker-compose.yml` sind reine Entwicklungs-Defaults.
> Für Staging/Produktion werden Schlüssel und Passwörter über Secrets gesetzt, niemals
> eingecheckt.

## Struktur (wächst mit Milestone 3+)

```
server/
├── docker-compose.yml     # Nakama + Postgres für lokale Entwicklung
└── modules/               # Custom-Runtime (Go/TypeScript): RPCs & Match-Handler
```

## Autoritäts-Grundsatz

Jede fairness- oder wirtschaftsrelevante Aktion (Bewegung, Fähigkeit, Loot, Handel,
Auktion) wird hier **serverseitig validiert** — Cooldown, Reichweite, Ressourcen,
Position, Rate-Limits. Der Client sagt nur voraus und stellt dar. Siehe
docs/ARCHITECTURE.md §5 und docs/adr/0002-backend-nakama.md.
