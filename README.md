# Datei-Zeitplaner

Eine lokale Desktop-App (Electron), die beliebige Dateien nach einem Zeitplan
öffnet – einmalig, täglich oder wöchentlich. Dateien werden mit dem jeweiligen
Standardprogramm des Betriebssystems geöffnet (z. B. PDF im PDF-Reader,
`.xlsx` in Excel, `.exe`/`.bat` wird gestartet, Ordner im Explorer geöffnet).

> Ein reines HTML/JS-Skript im Browser kann aus Sicherheitsgründen keine
> lokalen Dateien öffnen oder Programme starten. Deshalb läuft die
> Oberfläche hier in einer Electron-App mit einem kleinen Node.js-Backend,
> das die eigentliche Öffnen-Aktion und den Zeitplan übernimmt.

**Firmen-PC ohne Installationsrechte?** Im Ordner [`powershell/`](powershell/)
liegt eine alternative Variante, die ganz ohne Node.js/Electron und ohne
Installation auskommt – nur PowerShell und die native Windows-Aufgaben-
planung. Siehe [`powershell/README.md`](powershell/README.md).

## Voraussetzungen

- [Node.js](https://nodejs.org) (Version 18 oder neuer)

## Installation

```bash
npm install
```

## Starten

```bash
npm start
```

Es öffnet sich ein Fenster mit der Oberfläche. Die App muss dauerhaft
geöffnet bleiben (kann minimiert werden), damit geplante Dateien zur
richtigen Zeit automatisch geöffnet werden.

## Nutzung

1. Über **„Durchsuchen…“** die gewünschte Datei auswählen.
2. Wiederholung wählen: **Einmalig**, **Täglich** oder **Wöchentlich**.
3. Datum/Wochentag (falls zutreffend) und Uhrzeit angeben.
4. **„Zeitplan hinzufügen“** klicken.

Der Eintrag erscheint in der Liste **„Geplante Einträge“**. Dort lässt er
sich jederzeit deaktivieren, sofort testweise öffnen oder löschen. Im
Bereich **„Verlauf“** wird protokolliert, wann welche Datei geöffnet wurde.

Alle Einträge werden lokal gespeichert (`schedules.json` im
Anwendungsdatenordner) und bleiben nach einem Neustart der App erhalten.

## Als Windows-.exe verpacken

Mit [electron-builder](https://www.electron.build) lässt sich aus dem
Projekt eine eigenständige Windows-Anwendung erzeugen (Installer + portable
.exe), die kein installiertes Node.js oder `npm start` mehr benötigt.

```bash
npm install
npm run dist:win
```

Das Ergebnis liegt danach im Ordner `dist/`:

- `Datei-Zeitplaner Setup <version>.exe` – Installer (NSIS)
- `Datei-Zeitplaner <version>.exe` – portable Version, läuft ohne Installation

**Wichtig:** Am einfachsten wird dieser Befehl direkt auf einem
Windows-Rechner ausgeführt. Baut man den Windows-Build stattdessen unter
Linux oder macOS, wird zusätzlich [Wine](https://www.winehq.org/) benötigt,
damit electron-builder den NSIS-Installer erstellen kann.

Die erzeugte `.exe` einfach doppelklicken bzw. installieren – die App
verhält sich danach genauso wie mit `npm start`, inklusive Speicherung des
Zeitplans zwischen Programmstarts.

## Projektstruktur

```
main.js            Electron-Hauptprozess: Zeitplan-Logik, Dateien öffnen, Speicherung
preload.js          Sichere Bridge zwischen Oberfläche und Hauptprozess
renderer/index.html Oberfläche
renderer/style.css  Styling
renderer/renderer.js Oberflächen-Logik
```
