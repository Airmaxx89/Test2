extends Node
class_name ZoneData
## World layout for the Eichenmark starting region: zone bounds, NPC
## placements, quest-location markers and mob spawn points. All coordinates
## are in world-space blocks (1 unit = 1 voxel).

const ZONES := {
	"eichenfeld": {"name": "Eichenfeld", "x": Vector2i(-48, 48), "biome": "meadow"},
	"wolfsschlucht": {"name": "Wolfsschlucht", "x": Vector2i(48, 148), "biome": "forest"},
	"steinbrueck": {"name": "Steinbrück", "x": Vector2i(148, 268), "biome": "hills"},
	"rabenmoor": {"name": "Rabenmoor", "x": Vector2i(268, 368), "biome": "swamp"},
	"grimmwacht": {"name": "Grimmwacht", "x": Vector2i(368, 468), "biome": "ruins"},
}

const Z_RANGE := Vector2i(-64, 64)

const NPCS := [
	{"id": "aeltester_berthold", "name": "Ältester Berthold", "zone": "eichenfeld", "x": 0, "z": 10},
	{"id": "baeuerin_hilde", "name": "Bäuerin Hilde", "zone": "eichenfeld", "x": -14, "z": -8},
	{"id": "schmied_rutger", "name": "Schmied Rutger", "zone": "eichenfeld", "x": 14, "z": -10},
	{"id": "jaegerin_elsbeth", "name": "Jägerin Elsbeth", "zone": "wolfsschlucht", "x": 58, "z": 0},
	{"id": "vogt_konrad", "name": "Vogt Konrad", "zone": "steinbrueck", "x": 156, "z": 0},
	{"id": "minenvorsteher_alrik", "name": "Minenvorsteher Alrik", "zone": "steinbrueck", "x": 196, "z": 24},
	{"id": "einsiedlerin_grete", "name": "Einsiedlerin Grete", "zone": "rabenmoor", "x": 278, "z": 0},
	{"id": "hauptmann_ansgar", "name": "Hauptmann Ansgar", "zone": "grimmwacht", "x": 380, "z": 0},
]

## reach-type quest objectives resolve against these markers.
const LOCATIONS := {
	"wolfsschlucht_eingang": {"x": 50, "z": 0, "radius": 10},
	"steinbrueck_tor": {"x": 150, "z": 0, "radius": 10},
	"rabenmoor_rand": {"x": 270, "z": 0, "radius": 10},
	"grimmwacht_tor": {"x": 370, "z": 0, "radius": 10},
}

const SPAWNERS := [
	{"id": "s_wolf_eichenfeld", "mob": "wolf", "x": 22, "z": 22, "radius": 18, "max_alive": 3, "respawn": 20.0},
	{"id": "s_boar_eichenfeld", "mob": "wildschwein", "x": -22, "z": 20, "radius": 18, "max_alive": 3, "respawn": 20.0},
	{"id": "s_kobold_eichenfeld", "mob": "kobold", "x": 30, "z": -32, "radius": 16, "max_alive": 3, "respawn": 20.0},
	{"id": "s_wolf_wolfsschlucht", "mob": "wolf", "x": 75, "z": 30, "radius": 25, "max_alive": 4, "respawn": 18.0},
	{"id": "s_bandit_wolfsschlucht", "mob": "wegelagerer", "x": 100, "z": -25, "radius": 20, "max_alive": 3, "respawn": 25.0},
	{"id": "s_spider_wolfsschlucht", "mob": "riesenspinne", "x": 125, "z": 25, "radius": 20, "max_alive": 3, "respawn": 25.0},
	{"id": "s_kobold_steinbrueck", "mob": "kobold", "x": 172, "z": -30, "radius": 20, "max_alive": 3, "respawn": 20.0},
	{"id": "s_bandit_steinbrueck", "mob": "wegelagerer", "x": 205, "z": 30, "radius": 20, "max_alive": 3, "respawn": 25.0},
	{"id": "s_skeleton_steinbrueck", "mob": "skelett", "x": 228, "z": 0, "radius": 20, "max_alive": 3, "respawn": 28.0},
	{"id": "s_boss_bandit_captain", "mob": "raeuberhauptmann", "x": 244, "z": 0, "radius": 6, "max_alive": 1, "respawn": 600.0},
	{"id": "s_swampthing_rabenmoor", "mob": "sumpfschrat", "x": 305, "z": 22, "radius": 25, "max_alive": 4, "respawn": 25.0},
	{"id": "s_skeleton_rabenmoor", "mob": "skelett", "x": 335, "z": -22, "radius": 20, "max_alive": 3, "respawn": 28.0},
	{"id": "s_bandit_grimmwacht", "mob": "wegelagerer", "x": 392, "z": 22, "radius": 20, "max_alive": 4, "respawn": 25.0},
	{"id": "s_skeleton_grimmwacht", "mob": "skelett", "x": 415, "z": -22, "radius": 20, "max_alive": 4, "respawn": 28.0},
	{"id": "s_swampthing_grimmwacht", "mob": "sumpfschrat", "x": 432, "z": 0, "radius": 20, "max_alive": 3, "respawn": 28.0},
	{"id": "s_boss_old_guardian", "mob": "alter_waechter", "x": 462, "z": 0, "radius": 8, "max_alive": 1, "respawn": 1800.0},
]

static func get_zone(x: int) -> String:
	for id in ZONES.keys():
		var bounds: Vector2i = ZONES[id]["x"]
		if x >= bounds.x and x < bounds.y:
			return id
	return "eichenfeld"

static func get_biome(x: int) -> String:
	return ZONES[get_zone(x)]["biome"]
