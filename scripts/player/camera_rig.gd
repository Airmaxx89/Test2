extends Node3D
class_name CameraRig
## Third-Person-Kamera mit Touch-Drag-Rotation und optionalem Pinch-Zoom.
## Folgt dem Spieler weich (Spring-Arm gegen Wand-Clipping).
##
## Touch-Steuerung wird NUR auf der rechten Bildschirmhaelfte ausgewertet,
## damit sie sich nicht mit dem Joystick (links) ueberschneidet. Multi-Touch-faehig.

@export var target_path: NodePath
@export var follow_height := 1.6
@export var distance := 6.0
@export var min_distance := 3.0
@export var max_distance := 10.0
@export var rotation_sensitivity := 0.006
@export var min_pitch := -0.9         # nach unten
@export var max_pitch := 0.4          # nach oben
@export var follow_lerp := 10.0

@onready var _yaw_node: Node3D = $Yaw
@onready var _pitch_node: Node3D = $Yaw/Pitch
@onready var _spring: SpringArm3D = $Yaw/Pitch/SpringArm3D

var _target: Node3D
var _yaw := 0.0
var _pitch := -0.35

# Touch-Tracking (fuer Rotation & Pinch).
var _drag_touch_index := -1
var _last_drag_pos := Vector2.ZERO
# Pinch:
var _touch_points: Dictionary = {}    # index -> Vector2
var _last_pinch_dist := -1.0

func _ready() -> void:
	if target_path:
		_target = get_node_or_null(target_path)
	_spring.spring_length = distance
	# Kamera von Physik-Frames entkoppeln fuer smoothes Bild -> _process.
	set_physics_process(false)

func set_target(t: Node3D) -> void:
	_target = t

func _process(delta: float) -> void:
	if _target == null:
		# Ziel spaet finden (Spieler wird ggf. nach der Kamera erstellt).
		_target = get_tree().get_first_node_in_group("player")
		if _target == null:
			return
	# Weich der Spielerposition folgen.
	var desired: Vector3 = _target.global_position + Vector3.UP * follow_height
	global_position = global_position.lerp(desired, clampf(follow_lerp * delta, 0.0, 1.0))
	# Rotation anwenden.
	_yaw_node.rotation.y = _yaw
	_pitch_node.rotation.x = _pitch
	_spring.spring_length = lerp(_spring.spring_length, distance, clampf(8.0 * delta, 0, 1))

func _unhandled_input(event: InputEvent) -> void:
	# --- Touch (Screen) ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			# Nur rechte Bildschirmhaelfte fuer Kamera-Drag.
			if event.position.x > get_viewport().get_visible_rect().size.x * 0.5 and _drag_touch_index == -1:
				_drag_touch_index = event.index
				_last_drag_pos = event.position
		else:
			_touch_points.erase(event.index)
			if event.index == _drag_touch_index:
				_drag_touch_index = -1
			_last_pinch_dist = -1.0

	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		# Pinch-Zoom bei genau zwei Fingern.
		if _touch_points.size() == 2:
			_handle_pinch()
		elif event.index == _drag_touch_index:
			var d := event.position - _last_drag_pos
			_apply_rotation(d)
			_last_drag_pos = event.position

	# --- Maus (Desktop-Test): rechte Taste zum Drehen, Rad zum Zoomen ---
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_apply_rotation(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - 0.5, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + 0.5, min_distance, max_distance)

func _apply_rotation(motion: Vector2) -> void:
	_yaw -= motion.x * rotation_sensitivity
	_pitch = clampf(_pitch - motion.y * rotation_sensitivity, min_pitch, max_pitch)

func _handle_pinch() -> void:
	var pts: Array = _touch_points.values()
	var dist: float = pts[0].distance_to(pts[1])
	if _last_pinch_dist > 0.0:
		var delta := dist - _last_pinch_dist
		# Auseinander -> heranzoomen (Distanz verringern).
		distance = clampf(distance - delta * 0.02, min_distance, max_distance)
	_last_pinch_dist = dist

func get_yaw() -> float:
	return _yaw
