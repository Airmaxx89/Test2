extends Node
class_name Health
## Runtime health for any character. Initialized from a CharacterStats resource.
## Emits signals so UI and gameplay can react without hard coupling.

signal health_changed(current: int, maximum: int)
signal died

@export var stats: CharacterStats

var maximum: int = 1
var current: int = 1

func _ready() -> void:
	if stats != null:
		maximum = maxi(1, stats.max_health)
	current = maximum
	health_changed.emit(current, maximum)

func take_damage(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	current = clampi(current - amount, 0, maximum)
	health_changed.emit(current, maximum)
	if current == 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0 or not is_alive():
		return
	current = clampi(current + amount, 0, maximum)
	health_changed.emit(current, maximum)

func is_alive() -> bool:
	return current > 0
