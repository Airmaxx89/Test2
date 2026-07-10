# Aethermoor — Game Design Bible

> **Status:** Lebendes Dokument. Dies ist die verbindliche Referenz für Lore, Welt,
> Systeme und Balancing über alle Entwicklungssessions hinweg. Änderungen an
> Kernsystemen werden zusätzlich als ADR in `docs/adr/` festgehalten.
>
> **Genre:** Stylisiertes Fantasy-MMORPG · **Plattform:** Android (Touch-first) ·
> **Perspektive:** Anpassbare 3rd-Person / leicht erhöhte Schrägsicht (mobil optimiert).

---

## 1. Vision & Design-Säulen

Aethermoor ist ein für Smartphones **von Grund auf** entworfenes MMORPG. Es ist kein
auf Touch portiertes PC-Spiel. Jedes System wird an drei Säulen gemessen:

1. **Mobile-First.** Bedienbar mit ein oder zwei Händen. Sessions von 5 Minuten
   (Tagesquest) bis 2 Stunden (Raid) sind gleichermaßen befriedigend.
2. **Serverautoritativ & fair.** Der Server ist die einzige Wahrheit. Kein Client
   entscheidet über Schaden, Loot oder Position. Anti-Cheat ist Grundprinzip, kein Addon.
3. **Erweiterbar über Jahre.** Neue Kontinente, Klassen, Berufe und Events entstehen
   als Daten/Module, nicht als Umbau am Kern.

**Art Direction:** Modern-stylisiert, farbkräftiges Fantasy (Referenzen: WoW, Albion,
Tarisland, Diablo Immortal). Klare Silhouetten, lesbare Lichtstimmung, performant auf
Mittelklasse-Android. Kein Fotorealismus.

---

## 2. Lore & Welt: Aethermoor

### 2.1 Setting
Die Welt **Aethermoor** wurde einst vom **Ätherstrom** durchzogen — einer
magischen Energie, die Leben, Magie und die Grenzen zwischen den Reichen speiste.
Vor einem Zeitalter zersplitterte der Ätherstrom im **Großen Riss**. Seither treiben
**Ätherscherben** durch die Welt: Quellen von Macht, Mutation und Konflikt. Fraktionen,
Völker und Kreaturen ringen um Kontrolle über diese Scherben.

### 2.2 Kontinente (erweiterbar)
Der Startkontinent ist **Silbermark**. Weitere Kontinente sind als spätere Content-Drops
vorgesehen (jeder ist ein eigenes, gestreamtes Weltmodul — siehe ARCHITECTURE §Weltstreaming).

**Silbermark — Startkontinent, Zonen:**
| Zone                | Biom / Atmosphäre        | Level | Besonderheit                          |
|---------------------|--------------------------|-------|---------------------------------------|
| Morgenau            | Grünland, Dorf, Ruhe     | 1–10  | Startgebiet, Tutorial-Onboarding      |
| Silberwald          | Dichter Wald, Nebel      | 8–20  | Kräuter, Wegelagerer, erster Dungeon  |
| Aschenmoor          | Sumpf, giftig, düster    | 18–30 | Seuchen-Debuffs, Alchemie-Rohstoffe   |
| Dornkamm            | Gebirge, Kälte, Wind     | 28–40 | Bergbau, Greifen-Reittier-Quest       |
| Glutwüste           | Wüste, Ruinen, Hitze     | 38–50 | Ätherscherben-Ausgrabung, Weltbosse   |
| Die Rissküste       | Zerbrochene Küste/Inseln | 45–55 | Endgame-Hub, Raid-Zugang              |

Jede Zone besitzt **eigene Musik, Wetterprofile, Vegetation, Gegner-Sets und Rohstoffe**
(datengetrieben definiert, siehe `World`-Modul).

### 2.3 Städte & soziale Hubs
- **Silbernfeste** (Hauptstadt, Fraktion Ordnung): Auktionshaus, Banken, Berufsmeister.
- **Rabennest** (Hauptstadt, Fraktion Freiheit): PvP-Anmeldung, Schwarzmarkt.
- **Neutralmarkt Wegkreuz**: fraktionsübergreifender Handel, Gildenhallen.

---

## 3. Fraktionen

Drei Machtblöcke ringen um die Ätherscherben. Fraktion beeinflusst PvP-Zugehörigkeit,
Ruf, exklusive Quests und Belohnungen — **nicht** die verfügbaren Klassen (jede Fraktion
kann jede Klasse spielen, um Balancing und Populationsverteilung zu sichern).

| Fraktion              | Ethos                          | Heimat        | Ruf-Belohnungen (Beispiel)     |
|-----------------------|--------------------------------|---------------|--------------------------------|
| **Bund der Ordnung**  | Kontrolle & Bewahrung d. Äthers| Silbernfeste  | Wachrüstungen, Ordens-Reittier |
| **Freien der Wildmark**| Freiheit, Natur, Widerstand   | Rabennest     | Bestien-Begleiter, Tarnkleidung|
| **Zirkel der Scherben**| Macht durch den Äther, neutral| Wegkreuz      | Arkane Skins, Rift-Zugänge     |

Ruf-Stufen: Feindlich → Neutral → Freundlich → Ehrenvoll → Verehrt → Exaltiert.

---

## 4. Spielbare Völker

Völker geben kleine, **nicht dominante** Passivboni (kein „Zwang zur Meta"). Rein
kosmetische + leichte thematische Ausrichtung.

| Volk         | Thematik              | Passivbonus (klein, ~1–2 %)          |
|--------------|-----------------------|--------------------------------------|
| **Menschen** | Vielseitig, anpassbar | +Erfahrungsgewinn                    |
| **Waldelfen**| Natur, Beweglichkeit  | +Bewegungstempo, Kräuterkunde        |
| **Steinzwerge**| Handwerk, Zähigkeit | +Bergbau, +Widerstand gegen Betäubung|
| **Ätherkin** | Rissberührt, arkan    | +Manaregeneration                    |
| **Wildlinge**| Bestienblut, roh      | +kritische Trefferchance im Nahkampf |

---

## 5. Klassen & Spezialisierungen

**5 Startklassen**, jede mit **2–3 Spezialisierungen**. Eine Klasse deckt idealerweise
mehrere Rollen (Tank/Heal/DPS) über ihre Specs ab, damit jeder Spieler flexibel bleibt.
Fähigkeiten sind für Touch entworfen: wenige, wirkungsvolle aktive Skills + Passive
statt überladener PC-Rotationen.

| Klasse            | Rolle(n)        | Spezialisierungen                                     |
|-------------------|-----------------|-------------------------------------------------------|
| **Wächter**       | Tank / Nah-DPS  | *Bollwerk* (Tank), *Klingensturm* (DPS)               |
| **Waldläufer**    | Fern-DPS        | *Scharfschütze* (Präzision), *Fallensteller* (Kontrolle)|
| **Magus**         | Magie-DPS       | *Feuerruf* (Burst), *Frostweber* (Kontrolle/AoE)      |
| **Kleriker**      | Heiler / Support| *Lichtquell* (Heal), *Racheengel* (Support-DPS)       |
| **Schattenklinge**| Nah-DPS / Stealth| *Meuchler* (Burst), *Klingentanz* (nachhaltiger DPS) |

**Design-Regel:** Aktive Fähigkeiten pro Spec: 5–6 (passend auf die Touch-Zauberleiste).
Tiefe entsteht durch **Talentbäume, Ausrüstung, Combos und Timing**, nicht durch Buttonzahl.

---

## 6. Charakter-Progression

- **Level:** 1–55 (Start-Cap; pro Kontinent erweiterbar).
- **Attribute:** Stärke, Geschick, Intelligenz, Ausdauer, Willenskraft. Skalieren Schaden,
  Leben, Mana, Regeneration. Werden aus Level, Ausrüstung und Talenten abgeleitet
  (nie clientseitig gesetzt).
- **Talentbaum:** Pro Klasse, 1 Punkt/Level. Fördert Spielstil (defensiv/offensiv/Utility).
- **Skillbaum:** Schaltet Rang-Upgrades einzelner Fähigkeiten frei.
- **Passive Fähigkeiten:** Aus Talenten/Ausrüstung; verändern Kernmechaniken.
- **Ausrüstung:** Slots (Kopf, Schulter, Brust, Hände, Beine, Füße, 2× Ring, Amulett,
  Waffe(n), Nebenhand). Seltenheiten: Gewöhnlich → Ungewöhnlich → Selten → Episch →
  Legendär → **Ätherbeseelt** (legendär mit Riss-Effekt).
- **Reittiere & Haustiere:** Reittiere (Bodentempo; später fliegend). Haustiere (kosmetisch
  + kleine Utility).
- **Titel & Erfolge:** Serverseitig verfolgt; kosmetische Belohnungen, keine Kampfmacht.

---

## 7. Kampfsystem

**Echtzeit, serverautoritativ, mit Client-Prediction für Reaktivität.**

- **Reichweiten:** Nahkampf, Fernkampf, Magie.
- **Aktive Verteidigung:** Ausweichen (i-Frames, Ressourcenkosten), Blocken (Schild,
  gerichtet), Parieren (enges Timing-Fenster → Konter).
- **Trefferqualität:** Normal, Kritisch (Geschick/Intelligenz-skaliert), Streifschuss.
- **Statuszustände:** Buffs/Debuffs mit Stacks & Dauer; Kontroll­effekte (Betäubung, Wurzel,
  Verlangsamung) mit **abnehmender Wirkung (Diminishing Returns)** gegen PvP-Ketten.
- **Combo-System:** Bestimmte Fähigkeiten setzen/verbrauchen Marker (z. B. „Blutung"
  → Finisher verstärkt). Belohnt Reihenfolge statt Button-Spam.
- **Bossmechaniken:** Telegrafierte Flächen (mobil klar lesbar), Phasenwechsel,
  Add-Beschwörungen, Enrage-Timer.

**Mobile-Combat-Regeln:** Ziel-Automatik („Smart Targeting") mit manueller Übersteuerung;
großzügige Trefferfenster; Telegrafien optisch **und** farblich (Barrierefreiheit).

---

## 8. Gegner-KI

Modulares, verhaltensbasiertes KI-System (Behaviour-Trees / State-Machines, datengetrieben):

- **Standard-NPCs:** Patrouille, Aggro-Radius, Aggro-Verlust & Heimkehr (Reset), Assist
  (Gruppenaggro), Fluchtverhalten bei niedrigem Leben, gestufte „Intelligenz".
- **Elite/Bosse:** Mehrphasig, Spezialangriffe, Beschwörungen, Mechaniken mit
  Positionsanforderungen. Vollständig serverseitig aufgelöst.

---

## 9. Quests

- **Typen:** Haupt- (Story), Neben-, Tages-, Wochen-, Weltquests (Zonen-Events).
- **Struktur:** Datengetrieben (Ziel-Trigger: töten, sammeln, eskortieren, interagieren,
  erkunden). Fortschritt serverseitig validiert.
- **Dialoge & Entscheidungen:** Verzweigte Dialoge; Entscheidungen mit Ruf-/Belohnungsfolgen.
- **Rufsystem:** Fraktions- und Fraktionsuntergruppen-Ruf schaltet Belohnungen frei.

---

## 10. Berufe

Sammel- und Verarbeitungsberufe, paarweise sinnvoll kombinierbar. Datengetriebene
Rezepte; Materialqualität beeinflusst Ergebnis.

- **Sammeln:** Bergbau, Kräuterkunde, Angeln.
- **Verarbeiten:** Schmieden, Schneidern, Alchemie, Kochen, Verzaubern, Ingenieurskunst.

Jeder Beruf hat eigene Fortschrittsstufen, Rezeptfreischaltungen und trägt zur Wirtschaft bei.

---

## 11. Wirtschaft

- **Währung:** Gold (Sink-Design gegen Inflation: Reparatur, Reisen, Auktionsgebühren).
- **Handel:** NPC-Händler, direkter Spielerhandel (serverbestätigt), **Auktionshaus**
  (zentral, serverseitig; kein Client-Preisvertrauen).
- **Loot:** Gewichtete Beutetabellen serverseitig; personalisierter Loot in Instanzen
  (kein Ninja-Looting); Seltenheits-Drop-Raten datengetrieben.

---

## 12. Multiplayer (serverautoritativ, via Nakama)

- **Accounts & Login:** Nakama-Authentifizierung (Device/E-Mail; erweiterbar).
- **Charaktere:** Serverseitig gespeichert (Nakama Storage), nie clientautoritativ.
- **Sozial:** Gruppen, Gilden, Freunde, Chat (Kanäle: Welt, Zone, Gruppe, Gilde, Flüstern).
- **PvP:** Gewertete Arenen & offene PvP-Zonen; Matchmaking via Nakama.
- **Instanzen:** Dungeons & Raids als serverautoritative Match-Instanzen.
- **Anti-Cheat-Grundlagen:** Bewegungs-/Rate-Validierung, Server-Cooldowns, Sanity-Checks
  auf allen Aktionen. Details: ADR-0002 & `Networking`-Modul.
- **Synchronisation:** Zustandsreplikation mit Client-Prediction & Server-Reconciliation.

---

## 13. Benutzeroberfläche (ausschließlich Mobile)

**Keine PC-Elemente.** Alles Touch-first, frei anpassbar.

- **Bewegung:** Virtueller Joystick (links), Auto-Laufen, konfigurierbar.
- **Kampf:** Zauberleiste (rechts, Daumenzone), große Touchflächen, Smart-Targeting-Button.
- **Multi-Touch:** Bewegen + Zaubern + Kamera gleichzeitig.
- **HUD:** Minimap, Buff-/Debuff-Leiste, Schadenszahlen (togglebar), Ressourcenkugeln.
- **Fenster:** Weltkarte, Questlog, Inventar, Charakter, Talente, Gilde, Auktionshaus.
- **Ergonomie:** Wichtige Aktionen in Daumen-Reichweite; UI-Elemente frei verschiebbar
  und skalierbar; Einhandmodus-Preset.
- **Barrierefreiheit:** Farbenblind-Paletten, skalierbare Schrift, reduzierbare Effekte.
- **Controller:** Optionale, spätere Erweiterung (nicht Kernpfad).

---

## 14. Audio

- **Dynamische Musik:** Gebiets-Themes mit weichem Übergang; Kampfmusik-Layer bei Aggro.
- **Umgebung:** Wetter-, Biom- und Tageszeit-Ambient.
- **SFX:** Kampf, Magie, Fähigkeiten, UI. NPC-Stimmen (Barks/Vertonung ausgewählter Story).
- **Technik:** Komprimierte Streams für Musik, gepoolte One-Shots für SFX,
  Lautstärke-Buses (Master/Musik/SFX/Ambient/Stimme), Distanz-Attenuation.

---

## 15. Performance-Zielbudget (Android)

| Metrik              | High-End      | Mittelklasse   |
|---------------------|---------------|----------------|
| Bildrate            | stabil 60 FPS | stabil 30–60   |
| Draw Calls (Szene)  | Ziel < 150    | Ziel < 100     |
| Sichtbare Dreiecke  | Budget/LOD    | reduziert/LOD  |
| RAM (Client)        | moderat       | konservativ    |

Techniken (verbindlich, siehe ARCHITECTURE): LOD, Frustum-/Occlusion-Culling,
Object Pooling, Asset-Streaming, asynchrones Laden, Texture-Atlases, Instancing,
komprimierte Assets, Draw-Call-Minimierung. **Jedes Feature wird gegen dieses Budget
bewertet.**

---

## 16. Offene Design-Fragen (zu klären)

- Monetarisierung (kosmetisch, B2P, F2P mit Battlepass?) — **bewusst offen**, beeinflusst
  Wirtschafts-Sinks.
- Endgame-Kadenz (Raid-Reset-Zyklen, Season-Struktur).
- Cross-Region-Serverstrategie & Sharding-Schwellen.

Diese Fragen blockieren die frühe Entwicklung nicht, müssen aber vor der jeweiligen
Systemreife entschieden werden.
