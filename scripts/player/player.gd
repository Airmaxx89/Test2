extends CharacterBody3D
## Player movement for the isometric vertical slice.
## Input comes from the keyboard (WASD/arrows) and/or the virtual joystick,
## and is translated into world movement relative to the active camera so
## "up" on screen always means "away from the camera".

@export var move_speed: float = 6.0
## How quickly velocity approaches the target (units/sec^2).
@export var acceleration: float = 40.0
## How quickly the character turns to face the movement direction.
@export var turn_speed: float = 12.0
@export var input_dead_zone: float = 0.15

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 20.0)
var _camera: Camera3D
## Direction supplied by the virtual joystick (screen space, y-down).
var _joystick_dir: Vector2 = Vector2.ZERO

## Connected to the virtual joystick's signal from the world scene.
func set_move_input(direction: Vector2) -> void:
	_joystick_dir = direction

func _physics_process(delta: float) -> void:
	_resolve_camera()

	var input := _read_input()
	var world_dir := _input_to_world(input)
	var target_velocity := world_dir * move_speed

	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	if world_dir.length() > 0.01:
		var target_angle := atan2(world_dir.x, world_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

	move_and_slide()

## Combines keyboard and joystick; joystick wins when active.
func _read_input() -> Vector2:
	if _joystick_dir.length() >= input_dead_zone:
		return _joystick_dir
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

## Projects screen-space input onto the ground plane using the camera basis.
func _input_to_world(input: Vector2) -> Vector3:
	if _camera == null:
		return Vector3(input.x, 0.0, input.y)

	var basis := _camera.global_transform.basis
	var forward := -basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := basis.x
	right.y = 0.0
	right = right.normalized()

	# input.y is y-down (screen), so a negative y should move forward.
	var dir := right * input.x + forward * (-input.y)
	return dir.limit_length(1.0)

func _resolve_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
