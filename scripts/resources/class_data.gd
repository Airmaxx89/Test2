extends Resource
class_name ClassData
## Charakter-Klasse (Warrior, Mage) mit Basis-Stats, Wachstum pro Level und Skills.

@export var id: StringName = &""
@export var display_name: String = "Class"
@export_multiline var description: String = ""
@export var body_color: Color = Color.WHITE   # Platzhalter-Optik fuer Charakter

@export_group("Basis-Stats (Level 1)")
@export var base_health: int = 100
@export var base_mana: int = 50
@export var base_strength: int = 10
@export var base_intellect: int = 10
@export var base_stamina: int = 10

@export_group("Wachstum pro Level")
@export var health_per_level: int = 20
@export var mana_per_level: int = 10
@export var strength_per_level: int = 2
@export var intellect_per_level: int = 2
@export var stamina_per_level: int = 2

@export_group("Faehigkeiten")
## Skill-IDs; werden von Database aufgeloest.
@export var starter_skill_ids: Array = []
## Skillbaum: Level -> freischaltbare Skill-ID (einfacher linearer Baum)
@export var skill_unlocks: Dictionary = {}    # { 3: &"skill_id", 6: &"skill_id", ... }
@export var primary_stat: StringName = &"strength"

func stats_at_level(level: int) -> Dictionary:
	var l := maxi(level - 1, 0)
	return {
		&"max_health": base_health + health_per_level * l,
		&"max_mana": base_mana + mana_per_level * l,
		&"strength": base_strength + strength_per_level * l,
		&"intellect": base_intellect + intellect_per_level * l,
		&"stamina": base_stamina + stamina_per_level * l,
	}
