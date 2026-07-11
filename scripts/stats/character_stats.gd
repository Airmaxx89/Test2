extends Resource
class_name CharacterStats
## Data-driven stat block for a character type (player or enemy).
## This is configuration only — runtime values like current health live in the
## Health component, so the same resource can be shared safely.

@export var display_name: String = "Character"
@export_range(1, 999) var level: int = 1
@export_range(1, 99999) var max_health: int = 100
@export_range(0, 99999) var attack_damage: int = 10
