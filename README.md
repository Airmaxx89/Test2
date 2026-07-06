# Datei-Zeitplaner

Eine lokale Desktop-App (Electron), die beliebige Dateien nach einem Zeitplan
öffnet – einmalig, täglich oder wöchentlich. Dateien werden mit dem jeweiligen
Standardprogramm des Betriebssystems geöffnet (z. B. PDF im PDF-Reader,
`.xlsx` in Excel, `.exe`/`.bat` wird gestartet, Ordner im Explorer geöffnet).

> Ein reines HTML/JS-Skript im Browser kann aus Sicherheitsgründen keine
> lokalen Dateien öffnen oder Programme starten. Deshalb läuft die
> Oberfläche hier in einer Electron-App mit einem kleinen Node.js-Backend,
> das die eigentliche Öffnen-Aktion und den Zeitplan übernimmt.

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

## Projektstruktur

```
main.js            Electron-Hauptprozess: Zeitplan-Logik, Dateien öffnen, Speicherung
preload.js          Sichere Bridge zwischen Oberfläche und Hauptprozess
renderer/index.html Oberfläche
renderer/style.css  Styling
renderer/renderer.js Oberflächen-Logik
```
