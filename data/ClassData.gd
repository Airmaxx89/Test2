extends Node
class_name ClassData
## Generic fantasy class archetypes with original ability names.

const CLASSES := {
	"krieger": {
		"name": "Krieger",
		"description": "Ein Nahkämpfer mit hoher Ausdauer, der im Kampf an Wut aufbaut.",
		"resource_name": "Wut",
		"resource_base": 100,
		"resource_regen": 0.0, # builds from dealing/taking damage, not passive regen
		"base_health": 120,
		"base_mana": 0,
		"health_per_level": 14,
		"weapon": "sword",
		"color": Color(0.7, 0.15, 0.15),
		"abilities": [
			{
				"id": "wuchtschlag",
				"name": "Wuchtschlag",
				"description": "Ein wuchtiger Schwertschlag, der zusätzlichen Schaden verursacht.",
				"cost": 20,
				"cooldown": 4.0,
				"range": "melee",
				"damage_mult": 1.8,
				"unlock_level": 1,
			},
			{
				"id": "schildblock",
				"name": "Schildblock",
				"description": "Erhöht kurzzeitig die Rüstung und reduziert erlittenen Schaden.",
				"cost": 15,
				"cooldown": 10.0,
				"range": "self",
				"damage_mult": 0.0,
				"unlock_level": 5,
			},
			{
				"id": "wirbelschlag",
				"name": "Wirbelschlag",
				"description": "Trifft alle Gegner in der Nähe.",
				"cost": 30,
				"cooldown": 8.0,
				"range": "melee_aoe",
				"damage_mult": 1.1,
				"unlock_level": 10,
			},
		],
	},
	"magier": {
		"name": "Magier",
		"description": "Ein Zauberkundiger, der mächtige Elementarzauber aus der Ferne wirkt.",
		"resource_name": "Mana",
		"resource_base": 100,
		"resource_regen": 5.0,
		"base_health": 80,
		"base_mana": 100,
		"health_per_level": 8,
		"weapon": "staff",
		"color": Color(0.2, 0.35, 0.75),
		"abilities": [
			{
				"id": "feuerball",
				"name": "Feuerball",
				"description": "Schleudert einen Feuerball auf einen Gegner.",
				"cost": 25,
				"cooldown": 3.0,
				"range": "ranged",
				"damage_mult": 2.0,
				"unlock_level": 1,
			},
			{
				"id": "frostschock",
				"name": "Frostschock",
				"description": "Ein Frostblitz, der den Gegner verlangsamt.",
				"cost": 20,
				"cooldown": 6.0,
				"range": "ranged",
				"damage_mult": 1.3,
				"unlock_level": 5,
			},
			{
				"id": "arkanexplosion",
				"name": "Arkanexplosion",
				"description": "Eine Explosion arkaner Energie um den Magier herum.",
				"cost": 40,
				"cooldown": 9.0,
				"range": "ranged_aoe",
				"damage_mult": 1.4,
				"unlock_level": 10,
			},
		],
	},
	"jaeger": {
		"name": "Jäger",
		"description": "Ein Meister des Bogens, der aus der Distanz präzise zuschlägt.",
		"resource_name": "Fokus",
		"resource_base": 100,
		"resource_regen": 8.0,
		"base_health": 95,
		"base_mana": 0,
		"health_per_level": 10,
		"weapon": "bow",
		"color": Color(0.2, 0.55, 0.25),
		"abilities": [
			{
				"id": "zielschuss",
				"name": "Zielschuss",
				"description": "Ein präzise gezielter Schuss mit erhöhtem Schaden.",
				"cost": 20,
				"cooldown": 4.0,
				"range": "ranged",
				"damage_mult": 1.9,
				"unlock_level": 1,
			},
			{
				"id": "mehrfachschuss",
				"name": "Mehrfachschuss",
				"description": "Feuert mehrere Pfeile auf nahe Gegner ab.",
				"cost": 30,
				"cooldown": 7.0,
				"range": "ranged_aoe",
				"damage_mult": 1.2,
				"unlock_level": 5,
			},
			{
				"id": "ausweichrolle",
				"name": "Ausweichrolle",
				"description": "Eine schnelle Rolle, die kurzzeitig unverwundbar macht.",
				"cost": 15,
				"cooldown": 12.0,
				"range": "self",
				"damage_mult": 0.0,
				"unlock_level": 10,
			},
		],
	},
}

static func get_class_ids() -> Array:
	return CLASSES.keys()

static func get_ability(class_id: String, ability_id: String) -> Dictionary:
	for ab in CLASSES[class_id]["abilities"]:
		if ab["id"] == ability_id:
			return ab
	return {}
