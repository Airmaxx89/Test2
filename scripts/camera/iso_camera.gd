extends Node3D
## Isometric camera rig. The rig follows a target on the ground; the child
## Camera3D sits at a fixed offset and looks back at the rig, giving a stable
## isometric view. Orthographic projection keeps the classic iso look.

@export var offset: Vector3 = Vector3(12.0, 14.0, 12.0)
@export var ortho_size: float = 16.0
@export var follow_speed: float = 8.0

@onready var _camera: Camera3D = $Camera3D

var _target: Node3D

func _ready() -> void:
	_apply_camera_settings()

func set_target(target: Node3D) -> void:
	_target = target
	if target != null:
		global_position = target.global_position
	_apply_camera_settings()

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var weight: float = clampf(follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(_target.global_position, weight)
	_camera.look_at(global_position, Vector3.UP)

func _apply_camera_settings() -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ortho_size
	_camera.position = offset
	_camera.look_at(global_position, Vector3.UP)
