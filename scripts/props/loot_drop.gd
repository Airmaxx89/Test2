extends Area3D
class_name LootDrop
## Aufsammelbarer Loot in der Welt (poolbar).
## Rotiert leicht, schwebt, und wandert bei Naehe zum Spieler ("Magnet").

@export var pickup_radius := 1.6
@export var magnet_radius := 4.0
@export var magnet_speed := 8.0

var _item_id: StringName = &""
var _amount := 1
var _t := 0.0
var _collected := false

@onready var _mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	add_to_group("loot")
	collision_layer = 1 << 7
	collision_mask = 0
	set_physics_process(true)

func setup(item_id: StringName, amount: int, pos: Vector3) -> void:
	_item_id = item_id
	_amount = amount
	_collected = false
	global_position = pos
	visible = true
	set_physics_process(true)
	# Farbe nach Item-Typ (grob) fuer visuelles Feedback.
	if _mesh:
		var item := Database.get_item(item_id)
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		match (item.type if item else 0):
			ItemData.ItemType.WEAPON, ItemData.ItemType.ARMOR:
				mat.albedo_color = Color(0.4, 0.6, 1.0)
			ItemData.ItemType.QUEST:
				mat.albedo_color = Color(1.0, 0.85, 0.2)
			_:
				mat.albedo_color = Color(0.6, 1.0, 0.5)
		mat.emission = mat.albedo_color * 0.6
		_mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if _collected:
		return
	_t += delta
	# Schweben + rotieren.
	if _mesh:
		_mesh.rotation.y += delta * 2.0
		_mesh.position.y = 0.4 + sin(_t * 3.0) * 0.1
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= magnet_radius:
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)
	if dist <= pickup_radius:
		_collect()

func _collect() -> void:
	_collected = true
	Events.item_added.emit(_item_id, _amount)
	Events.loot_dropped.emit(_item_id, global_position)
	var item := Database.get_item(_item_id)
	if item:
		Events.toast_message.emit("Erhalten: %s x%d" % [item.display_name, _amount])
	AudioManager.play_sfx("res://assets/audio/sfx_pickup.ogg")
	_despawn()

func _despawn() -> void:
	if get_meta("pool_path", "") != "":
		PoolManager.release(self)
	else:
		queue_free()

func _on_pool_acquire() -> void:
	_collected = false
	visible = true
	set_physics_process(true)

func _on_pool_release() -> void:
	set_physics_process(false)
