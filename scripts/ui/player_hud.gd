extends Control
## Displays the player's level and health, and (temporarily) exposes debug
## buttons to test damage/heal. Purely a view: it reacts to Health signals and
## calls back into Health for the debug buttons.
## NOTE: the debug buttons are temporary and will be removed once real combat
## deals damage (Step 3).

@export var debug_amount: int = 10

@onready var _level_label: Label = $Panel/VBox/LevelLabel
@onready var _health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var _health_label: Label = $Panel/VBox/HealthLabel
@onready var _damage_button: Button = $DebugButtons/DamageButton
@onready var _heal_button: Button = $DebugButtons/HealButton

var _health: Health

func bind_health(health: Health, stats: CharacterStats) -> void:
	_health = health
	if stats != null:
		_level_label.text = "Level %d" % stats.level
	health.health_changed.connect(_on_health_changed)
	_damage_button.pressed.connect(_on_damage_pressed)
	_heal_button.pressed.connect(_on_heal_pressed)
	_on_health_changed(health.current, health.maximum)

func _on_health_changed(current: int, maximum: int) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "%d / %d HP" % [current, maximum]

func _on_damage_pressed() -> void:
	_health.take_damage(debug_amount)

func _on_heal_pressed() -> void:
	_health.heal(debug_amount)
