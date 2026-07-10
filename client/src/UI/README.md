# UI-Modul (ausschließlich Mobile / Touch-first)

Virtueller Joystick, konfigurierbare Buttons, HUD (Minimap, Buff-Leiste,
Schadenszahlen) und Screens (Inventar, Charakter, Karte, Auktionshaus). Oberste
Schicht: darf von `Gameplay` und `Core` abhängen, wird selbst von niemandem referenziert.

**Keine PC-Elemente.** Bedienung mit einer oder zwei Händen, frei verschieb- und
skalierbare Elemente, große Touchflächen (siehe docs/GAME_DESIGN.md §13).

Geplante Unterordner (ab Milestone 2): `Controls/`, `HUD/`, `Screens/`.
