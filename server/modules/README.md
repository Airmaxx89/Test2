# Nakama Custom-Runtime-Module

Hier liegt die autoritative Custom-Spiellogik, die Nakama zur Laufzeit lädt
(`--runtime.path`). Zwei unterstützte Wege (Entscheidung in Milestone 3 per ADR):

- **Go-Plugin** (`.so`): höchste Performance, kompiliert gegen die Nakama-Version.
- **TypeScript/JavaScript**: schnellere Iteration, gebündelt nach `index.js`.

Verantwortlich u. a. für: server-validierte Kampfauflösung, Loot-Vergabe,
Handels-/Auktions-Transaktionen, Match-Handler für Instanzen (Dungeons/Raids) und
Anti-Cheat-Grundlagen (Rate-Limits, Plausibilitätsprüfungen).

Noch keine Module eingecheckt — Umsetzung beginnt mit Milestone 3 (siehe
docs/ROADMAP.md).
