extends Control
## Touch-friendly virtual joystick. Emits a normalized direction (y-down,
## screen space) whenever the knob moves. Works with mouse on desktop because
## "emulate_touch_from_mouse" is enabled in the project settings.

signal direction_changed(direction: Vector2)

## Maximum knob travel from center, in pixels.
@export var max_length: float = 90.0
@export var dead_zone: float = 0.15

@onready var _base: Control = $Base
@onready var _knob: Control = $Base/Knob

var _touch_index: int = -1

func _ready() -> void:
	_center_knob()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _touch_index == -1 and _base.get_global_rect().has_point(event.position):
				_touch_index = event.index
				_update_knob(event.position)
		elif event.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)

func _update_knob(pointer_global: Vector2) -> void:
	var center := _base.size * 0.5
	var offset := (pointer_global - _base.global_position) - center
	offset = offset.limit_length(max_length)
	_knob.position = center + offset - _knob.size * 0.5

	var dir := offset / max_length
	if dir.length() < dead_zone:
		dir = Vector2.ZERO
	direction_changed.emit(dir)

func _release() -> void:
	_touch_index = -1
	_center_knob()
	direction_changed.emit(Vector2.ZERO)

func _center_knob() -> void:
	_knob.position = _base.size * 0.5 - _knob.size * 0.5
