extends CharacterBody3D
class_name Player

const SPEED := 5.0
const JUMP_VELOCITY := 8.5
const ROTATE_SPEED := 0.006
const CAMERA_MIN_PITCH := deg_to_rad(-70)
const CAMERA_MAX_PITCH := deg_to_rad(15)
const INTERACT_RANGE := 3.0
const MELEE_RANGE := 2.2
const RANGED_MAX_RANGE := 16.0
const AOE_RADIUS := 6.0
const SHIELD_BLOCK_DURATION := 4.0
const SHIELD_BLOCK_REDUCTION := 0.5
const EVADE_DURATION := 1.2
const FROST_SLOW_FACTOR := 0.5
const FROST_SLOW_DURATION := 3.0

var camera_pivot: Node3D
var camera: Camera3D
var model: Node3D

var yaw: float = 0.0
var pitch: float = -0.35
var camera_distance: float = 6.0

var attack_cooldown: float = 0.0
var nearby_npc: Node3D = null
var target_mob: Node3D = null

var block_timer: float = 0.0
var evade_timer: float = 0.0
var walk_phase: float = 0.0
var idle_phase: float = 0.0

signal target_changed(mob: Node3D)


func _ready() -> void:
	add_to_group("player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)

	var race: Dictionary = RaceData.RACES[GameManager.race_id]
	var cls: Dictionary = ClassData.CLASSES[GameManager.class_id]
	model = CharacterModel.build(race["color"], cls["color"])
	add_child(model)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0, 1.5, 0)
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.position = Vector3(0, 0, camera_distance)
	camera.fov = 65.0
	camera.current = true
	camera_pivot.add_child(camera)


func _physics_process(delta: float) -> void:
	_handle_camera()
	_handle_movement(delta)
	_handle_actions(delta)
	_check_reach_locations()
	GameManager.world_position = global_position


func _handle_camera() -> void:
	var look := InputState.consume_look()
	yaw -= look.x * ROTATE_SPEED
	pitch -= look.y * ROTATE_SPEED
	pitch = clamp(pitch, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
	rotation.y = yaw
	camera_pivot.rotation.x = pitch
	camera.position = Vector3(0, 0, camera_distance)


func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	else:
		velocity.y = max(velocity.y, 0.0)
		if InputState.consume_jump():
			velocity.y = JUMP_VELOCITY

	var move := InputState.move_vector
	var input_dir := Vector3(move.x, 0, move.y)
	var move_dir := input_dir.rotated(Vector3.UP, yaw)
	var is_moving := move_dir.length() > 0.01
	if is_moving:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
		var target_angle := atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle - yaw, 0.25)
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 4.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 4.0 * delta)

	move_and_slide()

	if is_moving and is_on_floor():
		walk_phase += delta * 10.0
	idle_phase += delta
	CharacterModel.animate(model, walk_phase, is_moving and is_on_floor(), idle_phase)


func _handle_actions(delta: float) -> void:
	attack_cooldown = max(0.0, attack_cooldown - delta)
	block_timer = max(0.0, block_timer - delta)
	evade_timer = max(0.0, evade_timer - delta)
	_update_target_and_nearby_npc()

	if InputState.consume_attack() and attack_cooldown <= 0.0:
		_perform_basic_attack()
		attack_cooldown = 1.0

	for i in range(3):
		if InputState.consume_ability(i):
			_perform_ability(i)

	if InputState.consume_interact():
		_perform_interact()


func _update_target_and_nearby_npc() -> void:
	nearby_npc = null
	var closest_npc_dist := INTERACT_RANGE
	for npc in get_tree().get_nodes_in_group("npc"):
		var d: float = global_position.distance_to(npc.global_position)
		if d < closest_npc_dist:
			closest_npc_dist = d
			nearby_npc = npc

	var closest_mob: Node3D = null
	var closest_mob_dist := RANGED_MAX_RANGE
	for mob in get_tree().get_nodes_in_group("mob"):
		var d: float = global_position.distance_to(mob.global_position)
		if d < closest_mob_dist:
			closest_mob_dist = d
			closest_mob = mob

	if closest_mob != target_mob:
		if target_mob != null and is_instance_valid(target_mob):
			target_mob.set_targeted(false)
		target_mob = closest_mob
		if target_mob != null:
			target_mob.set_targeted(true)
		target_changed.emit(target_mob)


func _perform_basic_attack() -> void:
	if target_mob == null:
		return
	var d: float = global_position.distance_to(target_mob.global_position)
	if d > MELEE_RANGE:
		return
	target_mob.take_damage(GameManager.get_attack_damage())
	if GameManager.class_id == "krieger":
		# Warriors build their "Wut" (rage) resource from landing attacks
		# instead of regenerating it passively.
		GameManager.gain_resource(15.0)


func _perform_ability(index: int) -> void:
	var abilities: Array = GameManager.get_class_abilities()
	if index >= abilities.size():
		return
	var ab: Dictionary = abilities[index]
	if not GameManager.is_ability_ready(ab["id"]):
		return
	if not GameManager.spend_resource(ab["cost"]):
		return
	GameManager.trigger_cooldown(ab["id"], ab["cooldown"])

	if ab["range"] == "self":
		_apply_self_ability(ab["id"])
		return

	if target_mob == null:
		return
	var d: float = global_position.distance_to(target_mob.global_position)
	var max_range: float = MELEE_RANGE if ab["range"].begins_with("melee") else RANGED_MAX_RANGE
	if d > max_range:
		return
	var dmg := int(GameManager.get_attack_damage() * float(ab["damage_mult"]))
	target_mob.take_damage(dmg)
	if ab["id"] == "frostschock":
		target_mob.apply_slow(FROST_SLOW_FACTOR, FROST_SLOW_DURATION)

	if ab["range"].ends_with("aoe"):
		for mob in get_tree().get_nodes_in_group("mob"):
			if mob != target_mob and global_position.distance_to(mob.global_position) <= AOE_RADIUS:
				mob.take_damage(dmg)


func _apply_self_ability(ability_id: String) -> void:
	match ability_id:
		"schildblock":
			block_timer = SHIELD_BLOCK_DURATION
		"ausweichrolle":
			evade_timer = EVADE_DURATION


func _perform_interact() -> void:
	if nearby_npc != null:
		nearby_npc.interact()


func _check_reach_locations() -> void:
	for location_id in ZoneData.LOCATIONS.keys():
		var loc: Dictionary = ZoneData.LOCATIONS[location_id]
		var flat := Vector2(global_position.x, global_position.z)
		var target := Vector2(loc["x"], loc["z"])
		if flat.distance_to(target) <= float(loc["radius"]):
			QuestManager.notify_reach(location_id)


func take_damage(amount: float) -> void:
	if evade_timer > 0.0:
		return
	var final_amount := amount
	if block_timer > 0.0:
		final_amount *= (1.0 - SHIELD_BLOCK_REDUCTION)
	GameManager.take_damage(final_amount)
