# ADR-0001: Engine — Godot 4 (C#)

- **Status:** Angenommen
- **Datum:** 2026-07-10
- **Entscheider:** Projektleitung (bestätigt durch Auftraggeber)

## Kontext
Zielplattform ist ausschließlich Android. Angestrebt werden stabile 60 FPS auf High-End-
und 30–60 FPS auf Mittelklasse-Geräten bei geringem Akku-/RAM-Verbrauch und schnellen
Ladezeiten. Der Grafikstil ist modern-stylisiert (kein Fotorealismus). Die Codebasis soll
über Jahre wartbar und für ein großes Team erweiterbar bleiben.

## Entscheidung
Der Client wird in **Godot 4 mit C# (.NET 8)** entwickelt.

## Betrachtete Alternativen
- **Unity (C#):** Industriestandard für Mobile-MMORPGs, größtes Asset-Ökosystem, ausgereiftes
  Android-Deployment. Nachteile: Lizenz-/Kostenmodell-Unsicherheiten, schwergewichtiger,
  Closed Source.
- **Unreal 5 (C++):** Grafisch stärkste Option, aber für stylisiertes Mobile überdimensioniert;
  höherer Akku-/GPU-Verbrauch und größere Builds widersprechen dem Mobile-Budget.
- **Godot 4 (C#):** Open Source, schlank, geringer Laufzeit-Overhead, guter Mobile-Renderer
  (Vulkan Mobile), C# ermöglicht saubere, testbare Architektur und potentielle Modell-
  Teilung mit .NET-Serverlogik.

## Begründung
Godot 4 passt am besten zu den drei harten Randbedingungen dieses Projekts: **Mobile-
Effizienz** (Akku/RAM/Ladezeit), **stylisierter Look** (kein Bedarf an Fotorealismus-
Pipeline) und **Offenheit/Kostenkontrolle** über eine mehrjährige Entwicklung. C# liefert
die für SOLID/Testbarkeit nötige Sprachqualität.

## Konsequenzen
- **Positiv:** Kleine Builds, guter Mobile-Renderer, keine Lizenzkosten, testbare C#-Logik,
  volle Quelltextkontrolle.
- **Negativ / Risiken:** Kleineres MMO-Ökosystem als Unity; weniger fertige Netcode-
  Lösungen. → Adressiert durch Nakama als Backend (ADR-0002) und eine bewusst dünne,
  gut gekapselte `Networking`-Schicht.
- **Folgeauflagen:** Logik strikt von Nodes trennen, damit Unit-Tests ohne Editor in CI
  laufen (siehe ARCHITECTURE §8, CODING_STANDARDS §4).
