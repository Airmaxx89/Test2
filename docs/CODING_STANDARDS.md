# Aethermoor — Coding Standards (verbindlich)

Diese Regeln gelten für den gesamten C#-Client-Code. Sie sichern eine über Jahre
wartbare, testbare, erweiterbare Codebasis für ein wachsendes Team.

---

## 1. Grundprinzipien
- **SOLID** ist Pflicht, nicht Kür. Insbesondere:
  - *Single Responsibility:* Eine Klasse, ein Grund zur Änderung.
  - *Open/Closed:* Erweiterung über neue Typen/Daten, nicht durch Ändern von Kernklassen.
  - *Dependency Inversion:* Gegen Interfaces (`IService`, `ILogger`) programmieren, nicht
    gegen Implementierungen. Auflösung über `ServiceLocator`.
- **Keine** Copy-Paste-Lösungen, Quick-Fixes oder „TODO: später aufräumen" ohne Ticket.
- **Keine Magic Numbers/Strings.** Benannte `const`/`static readonly` oder Konfig-Resource.
- Wenn bestehender Code beim Anfassen verbesserbar ist: **sofort refaktorieren** (Boy-Scout-Regel).

## 2. Naming (C#-Standard)
- `PascalCase`: Typen, Methoden, Properties, Konstanten, Events.
- `camelCase`: lokale Variablen, Parameter.
- `_camelCase`: private Felder.
- Interfaces mit `I`-Präfix (`IService`). Async-Methoden mit `Async`-Suffix.
- Aussagekräftige Namen, keine Abkürzungen außer etablierten (`id`, `ui`, `hp`).

## 3. Struktur & Größe
- Eine öffentliche Klasse pro Datei; Dateiname = Typname.
- Namespace spiegelt Ordner: `Aethermoor.Core.Events`, `Aethermoor.Gameplay.Combat`.
- Methoden bevorzugt < 40 Zeilen, Klassen bevorzugt < 300 Zeilen. Überschreitung ist ein
  Signal zum Aufteilen, kein Verbot — aber begründungspflichtig.

## 4. Godot + C# spezifisch
- Node-Skripte sind `public partial class X : Node…`. **Verhalten** ins Skript, **Zustand
  und Logik** wenn möglich in reine, Godot-freie Klassen (testbar in CI ohne Editor).
- Kein `GD.Print` im Produktivcode — immer `GameLogger`.
- Ereignisse zwischen Systemen über `EventBus`; Godot-Signale nur szenenlokal.
- Ressourcen (`Resource`/`.tres`) für datengetriebene Definitionen statt Hartcodierung.
- Nullable Reference Types aktiviert (`<Nullable>enable</Nullable>`) — Warnungen sind Fehler.

## 5. Dokumentation
- Öffentliche Typen und Methoden mit XML-Doc (`/// <summary>`), die das *Warum* erklärt,
  nicht das offensichtliche *Was*.
- Kommentardichte am umgebenden Code orientieren; keine Rausch-Kommentare.

## 6. Fehlerbehandlung
- Erwartbare Fehler (Netzwerk, Laden) explizit behandeln und über `GameLogger` protokollieren.
- Keine leeren `catch`-Blöcke. Kein Verschlucken von Ausnahmen.

## 7. Performance-Bewusstsein
- In Hot-Loops (`_Process`, `_PhysicsProcess`, Render-/Netzwerkpfaden): Allokationen vermeiden,
  Object Pooling nutzen, kein LINQ in per-Frame-Pfaden.
- Jede Änderung an Renderpfaden/Hot-Loops nennt im PR ihre Performance-Auswirkung.

## 8. Tests
- Neue Kern-/Gameplay-Logik kommt mit Unit-Tests (Godot-frei, CI-lauffähig).
- Kein Merge, wenn CI-Tests/Analyzer fehlschlagen.

## 9. Commits & Branches
- Entwicklung auf Feature-Branches; aussagekräftige, imperative Commit-Messages.
- Ein Commit = eine logische Änderung. Keine „WIP"-Sammelcommits im Main.
