# Datei-Zeitplaner (PowerShell-Variante)

Diese Variante kommt komplett ohne Node.js, Electron oder eine Installation
aus – sie nutzt ausschließlich Bordmittel von Windows:

- **PowerShell** + **WinForms** (beides Bestandteil von Windows/.NET) für die
  Oberfläche
- die native **Windows-Aufgabenplanung** (Task Scheduler) zum tatsächlichen
  zeitgesteuerten Öffnen der Dateien

Es muss also **keine App dauerhaft laufen**: Einträge werden einmal über die
Oberfläche angelegt, danach übernimmt Windows selbst das Auslösen zur
geplanten Zeit – auch wenn die Oberfläche geschlossen ist (der Rechner muss
zur geplanten Zeit an und der Benutzer angemeldet sein).

## Voraussetzungen

- Windows 10/11 (oder Windows Server 2012+)
- PowerShell (vorinstalliert)
- Keine Admin-Rechte nötig, solange die Standard-Policy des Unternehmens
  eigene Scheduled Tasks für den aktuellen Benutzer erlaubt (das ist der
  Windows-Normalfall)

## Einrichtung

1. Beide Dateien **`DateiZeitplaner.ps1`** und **`OpenFile.ps1`** zusammen in
   einen festen Ordner legen, z. B. `C:\Users\<Name>\Documents\DateiZeitplaner\`.
   Diesen Ordner danach nicht mehr verschieben – die angelegten Windows-Aufgaben
   verweisen auf den absoluten Pfad von `OpenFile.ps1`.

2. Falls die Dateien von einem anderen Rechner kopiert wurden, sind sie
   eventuell als "aus dem Internet heruntergeladen" markiert und werden
   blockiert. Einmalig entsperren:

   ```powershell
   Unblock-File .\DateiZeitplaner.ps1
   Unblock-File .\OpenFile.ps1
   ```

3. Skript starten (Rechtsklick → **„Mit PowerShell ausführen“**) oder über die
   Konsole:

   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\DateiZeitplaner.ps1
   ```

   `-ExecutionPolicy Bypass` gilt nur für diesen einen Aufruf und ändert keine
   Systemeinstellung. Falls das Unternehmen die Ausführungsrichtlinie per
   Gruppenrichtlinie fest erzwingt, kann dieser Parameter wirkungslos sein –
   in dem Fall bitte kurz mit der IT abklären, ob eigene Scheduled Tasks und
   PowerShell-Skripte erlaubt sind.

## Nutzung

1. Über **„Durchsuchen…“** die gewünschte Datei auswählen.
2. Wiederholung wählen: **Einmalig**, **Täglich** oder **Wöchentlich**.
3. Datum/Wochentag (falls zutreffend) und Uhrzeit angeben.
4. **„Zeitplan hinzufügen“** klicken – im Hintergrund wird automatisch eine
   Aufgabe im Task Scheduler unter `\DateiZeitplaner\` angelegt.

In der Liste **„Geplante Einträge“** lässt sich jeder Eintrag aktivieren/
deaktivieren, sofort testweise öffnen oder löschen (löscht auch die
zugehörige Windows-Aufgabe). Der Bereich **„Verlauf“** zeigt, wann welche
Datei geöffnet wurde – auch Ausführungen, die im Hintergrund stattfanden,
während die Oberfläche geschlossen war.

Alle Daten liegen in `%APPDATA%\DateiZeitplaner\`:

- `schedules.json` – die Einträge
- `verlauf.log` – das Protokoll

## Aufgaben manuell einsehen

Die angelegten Aufgaben lassen sich jederzeit direkt in der Windows-
Aufgabenplanung (`taskschd.msc`) unter dem Ordner **DateiZeitplaner**
einsehen, z. B. um den nächsten Ausführungszeitpunkt zu prüfen.

## Deinstallation

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Uninstall.ps1
```

Entfernt alle angelegten Windows-Aufgaben sowie die gespeicherten Zeitpläne
und den Verlauf. Anschließend können die Skriptdateien gefahrlos gelöscht
werden.

## Bekannte Einschränkungen

- Ein **einmaliger** Eintrag, der bereits ausgeführt wurde, lässt sich nicht
  einfach über „Aktivieren“ erneut auslösen (Windows führt einen bereits
  abgelaufenen Einmal-Trigger nicht erneut aus) – dafür einfach einen neuen
  Eintrag mit neuem Datum anlegen.
- Bearbeiten bestehender Einträge ist nicht vorgesehen – stattdessen löschen
  und neu anlegen.
- Die Aufgabe läuft nur, wenn der Benutzer zum geplanten Zeitpunkt angemeldet
  ist (Standardverhalten, kein Admin-Konto/Passwort-Speicherung nötig).
