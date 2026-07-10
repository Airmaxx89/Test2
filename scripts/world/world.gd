extends Node3D
class_name World
## Wurzel-Node des Spielgebiets "Eichenhain".
## - Spawnt den Spieler + Kamera
## - Startet Ambient-Musik
## - Instanziiert MultiMesh-Deko (Baeume/Gras) fuer minimale Draw Calls
## Der eigentliche Level-Aufbau (Terrain, NPCs, Spawner) liegt in world.tscn.

@export var player_scene: PackedScene
@export var camera_scene: PackedScene
@export var player_spawn_path: NodePath

@onready var _spawn_marker: Node3D = get_node_or_null(player_spawn_path)

func _ready() -> void:
	_spawn_player()
	AudioManager.play_music("res://assets/audio/music_forest_ambient.ogg")

func _spawn_player() -> void:
	if player_scene == null:
		player_scene = load("res://scenes/player/player.tscn")
	if camera_scene == null:
		camera_scene = load("res://scenes/player/camera_rig.tscn")

	var spawn_pos := Vector3(0, 1, 0)
	if _spawn_marker:
		spawn_pos = _spawn_marker.global_position
	# Save-Position bevorzugen (fortgesetztes Spiel).
	var saved: Vector3 = GameManager.character.get("spawn_position", Vector3.ZERO)
	if saved != Vector3.ZERO:
		spawn_pos = saved
	else:
		GameManager.character["spawn_position"] = spawn_pos

	# Kamera zuerst, damit Player sie referenzieren kann.
	var cam := camera_scene.instantiate()
	cam.name = "CameraRig"
	add_child(cam)

	var player := player_scene.instantiate()
	player.name = "Player"
	add_child(player)
	player.global_position = spawn_pos + Vector3.UP
