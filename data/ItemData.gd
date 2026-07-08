extends Node
class_name ItemData
## Item database. icon paths point at the procedurally generated icons in
## assets/textures/icons/ (see tools/generate_textures.py).

const ITEMS := {
	"sword": {
		"name": "Eichenklinge",
		"type": "weapon",
		"icon": "res://assets/textures/icons/sword.png",
		"damage": 8,
		"class_restriction": "krieger",
		"sell_value": 15,
	},
	"bow": {
		"name": "Kurzbogen",
		"type": "weapon",
		"icon": "res://assets/textures/icons/bow.png",
		"damage": 7,
		"class_restriction": "jaeger",
		"sell_value": 15,
	},
	"staff": {
		"name": "Weidenstab",
		"type": "weapon",
		"icon": "res://assets/textures/icons/staff.png",
		"damage": 6,
		"class_restriction": "magier",
		"sell_value": 15,
	},
	"health_potion": {
		"name": "Heiltrank",
		"type": "consumable",
		"icon": "res://assets/textures/icons/health_potion.png",
		"heal": 60,
		"sell_value": 5,
	},
	"mana_potion": {
		"name": "Manatrank",
		"type": "consumable",
		"icon": "res://assets/textures/icons/mana_potion.png",
		"restore_mana": 60,
		"sell_value": 5,
	},
	"wolf_pelt": {
		"name": "Wolfsfell",
		"type": "material",
		"icon": "res://assets/textures/icons/wolf_pelt.png",
		"sell_value": 3,
	},
	"boar_tusk": {
		"name": "Wildschweinhauer",
		"type": "material",
		"icon": "res://assets/textures/icons/boar_tusk.png",
		"sell_value": 2,
	},
	"coin": {
		"name": "Kupfermünze",
		"type": "currency",
		"icon": "res://assets/textures/icons/coin.png",
		"sell_value": 1,
	},
	"quest_scroll": {
		"name": "Beschriebene Schriftrolle",
		"type": "quest",
		"icon": "res://assets/textures/icons/quest_scroll.png",
		"sell_value": 0,
	},
	"iron_ore": {
		"name": "Eisenerz",
		"type": "material",
		"icon": "res://assets/textures/icons/iron_ore.png",
		"sell_value": 4,
	},
	"cloth": {
		"name": "Leinenstoff",
		"type": "material",
		"icon": "res://assets/textures/icons/cloth.png",
		"sell_value": 2,
	},
	"leather": {
		"name": "Leder",
		"type": "material",
		"icon": "res://assets/textures/icons/leather.png",
		"sell_value": 3,
	},
	"wood_log": {
		"name": "Holzscheit",
		"type": "material",
		"icon": "res://assets/textures/icons/wood_log.png",
		"sell_value": 1,
	},
	"apple": {
		"name": "Apfel",
		"type": "consumable",
		"icon": "res://assets/textures/icons/apple.png",
		"heal": 15,
		"sell_value": 1,
	},
	"bread": {
		"name": "Brotlaib",
		"type": "consumable",
		"icon": "res://assets/textures/icons/bread.png",
		"heal": 25,
		"sell_value": 1,
	},
}

static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})
