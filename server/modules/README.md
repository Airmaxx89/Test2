# Nakama Custom-Runtime-Module

Autoritative Spiellogik, die Nakama zur Laufzeit lädt (TypeScript → eine ES5-Datei,
siehe `tsconfig.json`). ADR in `docs/adr/0002-backend-nakama.md`.

## Bauen & Starten

```bash
cd server/modules
npm install        # nur TypeScript (Typen sind vendored, s. u.)
npm run build      # erzeugt build/index.js
cd .. && docker compose up   # mountet modules/build in den Nakama-Container
```

Erfolgskontrolle: Im Nakama-Log erscheint `Aethermoor-Server-Module geladen (Match: movement)`.

## Struktur

```
modules/
├── src/
│   ├── main.ts            # InitModule: registriert Match-Handler & RPCs
│   └── movement_match.ts  # Autoritativer Bewegungs-Match (Milestone 3)
├── types/nkruntime.d.ts   # Vendored Minimal-Typen der Nakama-Runtime (s. Kopfkommentar)
├── tsconfig.json          # ES5, outFile-Bündelung (kein Modulsystem — Runtime-Vorgabe)
└── build/index.js         # Artefakt (gitignored), wird in den Container gemountet
```

## Bewegungsprotokoll (Client ↔ Server)

| OpCode | Richtung        | Payload (JSON)                                        |
|--------|-----------------|-------------------------------------------------------|
| 1      | Client → Server | `{seq, dx, dy, dt}` — Eingabe mit Sequenznummer       |
| 2      | Server → Client | `{t, players: [{id, x, y, ack}]}` — Tick-Snapshot     |

Der Server integriert Eingaben mit **derselben Formel** wie die Client-Prediction
(`PredictionReconciler`): `position += richtung · MOVE_SPEED · dt`. `ack` ist die pro
Spieler zuletzt verarbeitete Sequenznummer und steuert die Client-Reconciliation.

**Serverseitige Validierung (Anti-Cheat-Grundlagen):** Richtungsvektoren werden auf
Länge 1 geklemmt, `dt` auf 0,1 s begrenzt, veraltete/wiederholte Sequenznummern verworfen
und Eingaben pro Tick rate-limitiert. Balancing-Konstanten (`MOVE_SPEED`) leben hier,
nicht im Client.

## RPCs

- `find_or_create_movement_match` → `{matchId}` — liefert das laufende Bewegungs-Match
  oder erstellt eines. Clients rufen dies nach dem Login und treten per Socket bei.

## Hinweis zu den vendored Typen

`types/nkruntime.d.ts` deklariert nur die von uns genutzte API-Oberfläche (die offiziellen
Typen aus `heroiclabs/nakama-common` sind in abgeschotteten Umgebungen nicht als
npm-Dependency beziehbar). Erweiterungen ergänzen die Signaturen anhand der offiziellen
Referenz — Abweichungen fallen im Integrationstest gegen den Docker-Stack auf.
