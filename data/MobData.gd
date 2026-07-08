extends Node
class_name MobData
## Generic fantasy/folklore creatures (wolves, boars, bandits, skeletons,
## spiders, kobolds - traditional monster tropes, not tied to any franchise).
## "Kobold" in particular is native German folklore, older than any modern game.

const MOBS := {
	"wolf": {
		"name": "Grauer Wolf",
		"level_range": Vector2i(1, 5),
		"base_health": 30,
		"base_damage": 4,
		"xp_base": 12,
		"speed": 3.5,
		"aggressive": true,
		"color": Color(0.5, 0.5, 0.55),
		"loot": {"wolf_pelt": 0.6, "coin": 0.3},
	},
	"wildschwein": {
		"name": "Wildschwein",
		"level_range": Vector2i(1, 6),
		"base_health": 40,
		"base_damage": 5,
		"xp_base": 14,
		"speed": 2.8,
		"aggressive": false,
		"color": Color(0.35, 0.25, 0.2),
		"loot": {"boar_tusk": 0.5, "coin": 0.3},
	},
	"kobold": {
		"name": "Kobold",
		"level_range": Vector2i(3, 8),
		"base_health": 35,
		"base_damage": 6,
		"xp_base": 16,
		"speed": 3.2,
		"aggressive": true,
		"color": Color(0.4, 0.6, 0.4),
		"loot": {"coin": 0.5, "cloth": 0.2, "iron_ore": 0.35},
	},
	"wegelagerer": {
		"name": "Wegelagerer",
		"level_range": Vector2i(6, 12),
		"base_health": 70,
		"base_damage": 9,
		"xp_base": 26,
		"speed": 3.0,
		"aggressive": true,
		"color": Color(0.3, 0.3, 0.3),
		"loot": {"coin": 0.7, "leather": 0.3, "iron_ore": 0.1},
	},
	"riesenspinne": {
		"name": "Riesenspinne",
		"level_range": Vector2i(8, 14),
		"base_health": 65,
		"base_damage": 10,
		"xp_base": 30,
		"speed": 3.8,
		"aggressive": true,
		"color": Color(0.15, 0.1, 0.1),
		"loot": {"cloth": 0.4, "coin": 0.4},
	},
	"skelett": {
		"name": "Verwittertes Skelett",
		"level_range": Vector2i(10, 17),
		"base_health": 90,
		"base_damage": 12,
		"xp_base": 38,
		"speed": 2.6,
		"aggressive": true,
		"color": Color(0.85, 0.85, 0.8),
		"loot": {"iron_ore": 0.3, "coin": 0.5},
	},
	"raeuberhauptmann": {
		"name": "Räuberhauptmann",
		"level_range": Vector2i(12, 12),
		"base_health": 220,
		"base_damage": 16,
		"xp_base": 200,
		"speed": 3.0,
		"aggressive": true,
		"is_boss": true,
		"color": Color(0.5, 0.1, 0.1),
		"loot": {"iron_ore": 1.0, "coin": 1.0, "leather": 0.6},
	},
	"sumpfschrat": {
		"name": "Sumpfschrat",
		"level_range": Vector2i(14, 19),
		"base_health": 130,
		"base_damage": 15,
		"xp_base": 55,
		"speed": 2.2,
		"aggressive": true,
		"color": Color(0.25, 0.35, 0.2),
		"loot": {"cloth": 0.3, "coin": 0.6, "quest_scroll": 0.4},
	},
	"alter_waechter": {
		"name": "Alter Wächter",
		"level_range": Vector2i(20, 20),
		"base_health": 600,
		"base_damage": 22,
		"xp_base": 1200,
		"speed": 1.8,
		"aggressive": true,
		"is_boss": true,
		"color": Color(0.45, 0.45, 0.5),
		"loot": {"iron_ore": 1.0, "coin": 1.0},
	},
}

static func get_mob(id: String) -> Dictionary:
	return MOBS.get(id, {})

static func scaled_health(id: String, level: int) -> int:
	var m = get_mob(id)
	return int(m["base_health"] * (1.0 + 0.12 * (level - m["level_range"].x)))

static func scaled_damage(id: String, level: int) -> int:
	var m = get_mob(id)
	return int(m["base_damage"] * (1.0 + 0.08 * (level - m["level_range"].x)))

static func xp_reward(id: String, level: int) -> int:
	var m = get_mob(id)
	return int(m["xp_base"] * (1.0 + 0.15 * (level - m["level_range"].x)))
