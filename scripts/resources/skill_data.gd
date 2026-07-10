extends Resource
class_name SkillData
## Definition eines aktiven Skills (Hotbar-Faehigkeit) inkl. Cooldown & Kosten.

enum SkillKind { MELEE, PROJECTILE, AOE, BUFF, HEAL }

@export var id: StringName = &""
@export var display_name: String = "Skill"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var kind: SkillKind = SkillKind.MELEE

@export_group("Kosten & Timing")
@export var mana_cost: int = 0
@export var cooldown: float = 3.0
@export var cast_range: float = 2.0          # Meter; Melee ~2, Ranged ~15
@export var required_level: int = 1

@export_group("Wirkung")
@export var base_damage: int = 10
@export var damage_scaling_stat: StringName = &"strength"  # "strength" | "intellect"
@export var scaling_factor: float = 1.0
@export var heal_amount: int = 0
@export var aoe_radius: float = 0.0          # >0 -> Flaechenschaden
@export var projectile_scene_path: String = "res://scenes/combat/projectile.tscn"

func compute_damage(caster_stats: Dictionary) -> int:
	## Schaden = Basis + (Scaling-Stat * Faktor)
	var stat_value: int = int(caster_stats.get(damage_scaling_stat, 0))
	return base_damage + int(round(float(stat_value) * scaling_factor))
