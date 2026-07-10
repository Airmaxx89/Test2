extends Control
class_name VirtualJoystick
## Multi-Touch-faehiger virtueller Joystick fuer Bewegung.
## - "Dynamic" Modus: erscheint dort, wo der Finger die linke Bildschirmhaelfte beruehrt.
## - Verfolgt seinen eigenen Touch-Index -> stoert Kamera/Buttons nicht.
## Gibt einen normalisierten Vektor aus: x=rechts(+)/links(-), y=vorne(+)/hinten(-).

signal moved(vector: Vector2)
signal released()

@export var max_radius := 110.0
@export var deadzone := 0.15
## Aktiv nur auf der linken Haelfte; rechte Haelfte bleibt fuer die Kamera frei.
@export var left_half_only := true

var _touch_index := -1
var _origin := Vector2.ZERO
var _output := Vector2.ZERO

@onready var _base: Control = $Base
@onready var _knob: Control = $Base/Knob

func _ready() -> void:
	# Vollflaechiger Eingabebereich, aber wir filtern per Position.
	mouse_filter = Control.MOUSE_FILTER_PASS
	# Groessen aus Radius ableiten -> funktioniert ohne Textur-Assets.
	var d := max_radius * 2.0
	_base.size = Vector2(d, d)
	_base.pivot_offset = _base.size * 0.5
	_knob.size = Vector2(max_radius * 0.7, max_radius * 0.7)
	_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knob.position = _base.size * 0.5 - _knob.size * 0.5
	_base.visible = false

func _gui_input(event: InputEvent) -> void:
	_process_event(event)

# Auch globale Screen-Touches abfangen (falls ausserhalb des Controls).
func _unhandled_input(event: InputEvent) -> void:
	_process_event(event)

func _process_event(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			if left_half_only and event.position.x > get_viewport().get_visible_rect().size.x * 0.5:
				return
			_touch_index = event.index
			_origin = event.position
			_base.global_position = _origin - _base.size * 0.5
			_base.visible = true
			_update_knob(event.position)
		elif not event.pressed and event.index == _touch_index:
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_knob(event.position)

func _update_knob(pos: Vector2) -> void:
	var delta := pos - _origin
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	_knob.position = _base.size * 0.5 + delta - _knob.size * 0.5
	var norm := delta / max_radius
	if norm.length() < deadzone:
		norm = Vector2.ZERO
	# Bildschirm-Y (nach unten +) in Welt-Vorwaerts (nach oben +) umdrehen.
	_output = Vector2(norm.x, -norm.y)
	moved.emit(_output)

func _reset() -> void:
	_touch_index = -1
	_output = Vector2.ZERO
	_base.visible = false
	_knob.position = _base.size * 0.5 - _knob.size * 0.5
	moved.emit(Vector2.ZERO)
	released.emit()

func get_output() -> Vector2:
	return _output
