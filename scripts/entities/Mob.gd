extends CharacterBody3D
class_name Mob
## Simple aggressive/passive mob AI: idle -> chase -> attack, plus death,
## loot and XP handling. Data comes from MobData, scaled by spawn level.

const MELEE_RANGE := 1.9
const AGGRO_RANGE := 10.0
const LEASH_RANGE := 18.0
const ATTACK_INTERVAL := 1.5

var mob_id: String
var level: int
var world: Node

var max_health: float
var health: float
var damage: int
var speed: float
var aggressive: bool
var is_boss: bool = false
var loot: Dictionary
var xp_value: int

var state: String = "idle"
var attack_cooldown: float = 0.0
var label: Label3D

var slow_timer: float = 0.0
var slow_factor: float = 1.0

const TARGETED_COLOR := Color(1.0, 0.85, 0.3)
const NORMAL_LABEL_COLOR := Color(1.0, 1.0, 1.0)

signal died()


func setup(id: String, lvl: int, w: Node) -> void:
	mob_id = id
	level = lvl
	world = w
	var data: Dictionary = MobData.get_mob(id)
	max_health = MobData.scaled_health(id, lvl)
	health = max_health
	damage = MobData.scaled_damage(id, lvl)
	speed = data["speed"]
	aggressive = data["aggressive"]
	is_boss = data.get("is_boss", false)
	loot = data["loot"]
	xp_value = MobData.xp_reward(id, lvl)

	add_to_group("mob")

	var model := CharacterModel.build(data["color"], data["color"].darkened(0.25))
	if is_boss:
		model.scale = Vector3(1.7, 1.7, 1.7)
	add_child(model)

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55 if is_boss else 0.4
	capsule.height = 2.6 if is_boss else 1.8
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position = Vector3(0, capsule.height / 2.0, 0)
	add_child(shape)

	label = Label3D.new()
	label.text = "%s (Lvl %d)" % [data["name"], lvl]
	label.position = Vector3(0, capsule.height + 0.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 30
	label.outline_size = 6
	add_child(label)


func _physics_process(delta: float) -> void:
	if state == "dead":
		return
	attack_cooldown = max(0.0, attack_cooldown - delta)
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_factor = 1.0

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var d: float = global_position.distance_to(player.global_position)

	match state:
		"idle":
			if aggressive and d < AGGRO_RANGE:
				state = "chase"
		"chase":
			if d > LEASH_RANGE:
				state = "idle"
			elif d < MELEE_RANGE:
				state = "attack"
			else:
				_move_toward(player.global_position, delta)
		"attack":
			if d > MELEE_RANGE * 1.4:
				state = "chase"
			else:
				_face(player.global_position)
				velocity.x = 0
				velocity.z = 0
				if attack_cooldown <= 0.0:
					player.take_damage(float(damage))
					attack_cooldown = ATTACK_INTERVAL

	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	move_and_slide()


func _move_toward(target_pos: Vector3, _delta: float) -> void:
	var dir := target_pos - global_position
	dir.y = 0
	if dir.length() > 0.1:
		dir = dir.normalized()
		var effective_speed := speed * slow_factor
		velocity.x = dir.x * effective_speed
		velocity.z = dir.z * effective_speed
		_face(target_pos)
	else:
		velocity.x = 0
		velocity.z = 0


func apply_slow(factor: float, duration: float) -> void:
	slow_factor = factor
	slow_timer = duration


func set_targeted(is_targeted: bool) -> void:
	if label:
		label.modulate = TARGETED_COLOR if is_targeted else NORMAL_LABEL_COLOR


func _face(target_pos: Vector3) -> void:
	var dir := target_pos - global_position
	if Vector2(dir.x, dir.z).length() > 0.05:
		rotation.y = atan2(dir.x, dir.z)


func take_damage(amount: float) -> void:
	if state == "dead":
		return
	health -= amount
	if state == "idle":
		state = "chase"
	if health <= 0.0:
		_die()


func _die() -> void:
	state = "dead"
	set_physics_process(false)
	QuestManager.notify_kill(mob_id)
	GameManager.add_xp(xp_value)
	for item_id in loot.keys():
		var chance: float = loot[item_id]
		if randf() <= chance:
			if item_id == "coin":
				GameManager.add_gold(randi_range(1, 5) + level)
			else:
				GameManager.add_item(item_id, 1)
	died.emit()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.6)
	tween.tween_callback(queue_free)
