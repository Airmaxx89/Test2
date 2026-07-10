extends Node3D
class_name EnemySpawner
## Spawnt Gegner eines Typs in einem Radius und haelt eine Population aufrecht
## (Respawn nach Verzoegerung). Nutzt Object-Pooling ueber PoolManager.
## Spawnt nur, wenn der Spieler grob in der Naehe ist -> spart CPU im Leerlauf.

@export var enemy_id: StringName = &"wolf"
@export var enemy_scene: PackedScene            # scenes/enemies/enemy.tscn
@export var max_alive := 4
@export var spawn_radius := 12.0
@export var respawn_delay := 8.0
@export var activation_distance := 60.0         # nur aktiv, wenn Spieler naeher

var _alive: Array = []
var _respawn_timer := 0.0
var _enemy_data: EnemyData

func _ready() -> void:
	_enemy_data = Database.get_enemy(enemy_id)
	if enemy_scene == null:
		enemy_scene = load("res://scenes/enemies/enemy.tscn")
	# Pool vorwaermen fuer ruckelfreie erste Spawns.
	PoolManager.prewarm("res://scenes/enemies/enemy.tscn", max_alive)
	# Erste Welle nach kurzer Zeit.
	_respawn_timer = 1.0

func _process(delta: float) -> void:
	# Aktivierungs-Check: nur arbeiten, wenn Spieler in Reichweite.
	var player := get_tree().get_first_node_in_group("player")
	if player == null or global_position.distance_to(player.global_position) > activation_distance:
		return

	# Tote/entfernte aus Liste raeumen.
	_alive = _alive.filter(func(e): return is_instance_valid(e) and not e.is_dead())

	if _alive.size() < max_alive:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_spawn_one()
			_respawn_timer = respawn_delay

func _spawn_one() -> void:
	if _enemy_data == null:
		return
	var enemy: Enemy = PoolManager.acquire("res://scenes/enemies/enemy.tscn")
	add_child(enemy)
	var angle := randf() * TAU
	var r := randf_range(2.0, spawn_radius)
	var offset := Vector3(cos(angle) * r, 0, sin(angle) * r)
	enemy.setup(_enemy_data, global_position + offset)
	_alive.append(enemy)
