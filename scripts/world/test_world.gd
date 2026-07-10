extends Node3D
## Wires the vertical-slice scene together: the joystick drives the player,
## and the camera rig follows the player. Kept intentionally thin.

@onready var _player: CharacterBody3D = $Player
@onready var _camera_rig: Node3D = $CameraRig
@onready var _joystick: Control = $HUD/VirtualJoystick

func _ready() -> void:
	_camera_rig.set_target(_player)
	_joystick.direction_changed.connect(_player.set_move_input)
