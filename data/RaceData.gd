extends Node
class_name RaceData
## Original fantasy race archetypes (generic tropes predating and outside any
## single franchise - human / dwarf / wood-elf are common to countless RPGs).

const RACES := {
	"mensch": {
		"name": "Mensch",
		"description": "Vielseitig und anpassungsfähig, zuhause in den Dörfern von Eichenmark.",
		"stat_mods": {"health": 0, "mana": 0, "stamina": 0, "strength": 1, "agility": 1, "intellect": 1},
		"color": Color(0.85, 0.68, 0.55),
	},
	"zwerg": {
		"name": "Zwerg",
		"description": "Zäh und kräftig, aus den Minen der Steinbrücker Hügel.",
		"stat_mods": {"health": 15, "mana": -10, "stamina": 5, "strength": 3, "agility": 0, "intellect": -1},
		"color": Color(0.8, 0.6, 0.45),
	},
	"waldelf": {
		"name": "Waldelf",
		"description": "Flink und naturverbunden, Hüter der Wälder um Wolfsschlucht.",
		"stat_mods": {"health": -10, "mana": 15, "stamina": 0, "strength": -1, "agility": 3, "intellect": 2},
		"color": Color(0.9, 0.8, 0.65),
	},
}

static func get_race_ids() -> Array:
	return RACES.keys()
