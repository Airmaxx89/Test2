extends CharacterBody3D
class_name Enemy
## Gegner mit einfacher Finite-State-Machine-KI.
## States: IDLE -> CHASE -> ATTACK -> (RETURN) -> DEAD
## Melee: laeuft ans Ziel, schlaegt in Reichweite.
## Ranged: haelt Abstand, feuert Projektile.
##
## Wird von EnemyData konfiguriert (setup). Poolbar (per PoolManager) fuer Waves.

enum State { IDLE, CHASE, ATTACK, RETURN, DEAD }

@export var data: EnemyData

var _state: State = State.IDLE
var _health := 0
var _spawn_pos := Vector3.ZERO
var _target: Node3D = null
var _attack_cd := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)
var _dead := false

@onready var _mesh: Node3D = $Body
@onready var _health_bar: Node3D = get_node_or_null("HealthBar3D")
@onready var _detect_area: Area3D = $DetectionArea
@onready var _vis_notifier: VisibleOnScreenNotifier3D = get_node_or_null("VisibleOnScreenNotifier3D")

func _ready() -> void:
	# WICHTIG: NICHT hier zur "enemies"-Gruppe hinzufuegen. Gepoolte, inaktive
	# Gegner wuerden sonst als gueltige Ziele am Ursprung erkannt. Gruppe wird
	# in _configure() (beim Aktivieren) gesetzt und in _on_pool_release() entfernt.
	collision_layer = 1 << 2      # enemy
	collision_mask = (1 << 0) | (1 << 1)   # world + player
	if data:
		_configure()
	# Performance: Wenn nicht sichtbar, KI-Physik drosseln.
	if _vis_notifier:
		_vis_notifier.screen_entered.connect(_on_onscreen)
		_vis_notifier.screen_exited.connect(_on_offscreen)

## Konfiguriert diesen Gegner nach EnemyData. Auch fuer Pool-Reuse nutzbar.
func setup(enemy_data: EnemyData, spawn_position: Vector3) -> void:
	data = enemy_data
	global_position = spawn_position
	_configure()

func _configure() -> void:
	_spawn_pos = global_position
	_health = data.max_health
	_dead = false
	_state = State.IDLE
	# Erst jetzt (aktiv) als Ziel auffindbar machen.
	if not is_in_group("enemies"):
		add_to_group("enemies")
	# Optik.
	if _mesh and _mesh.has_node("MeshInstance3D"):
		var mi: MeshInstance3D = _mesh.get_node("MeshInstance3D")
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data.body_color
		mi.material_override = mat
	# Detection-Radius setzen.
	if _detect_area and _detect_area.has_node("CollisionShape3D"):
		var cs: CollisionShape3D = _detect_area.get_node("CollisionShape3D")
		if cs.shape is SphereShape3D:
			(cs.shape as SphereShape3D).radius = data.detection_radius
	_update_health_bar()

# ---------------------------------------------------------------------------
#  State Machine
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# Sicherheitshalt: inaktive/gepoolte Gegner (ohne data) nie verarbeiten.
	if _dead or data == null:
		return
	if _attack_cd > 0.0:
		_attack_cd -= delta

	# Schwerkraft.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	match _state:
		State.IDLE:
			_state_idle()
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.RETURN:
			_state_return(delta)

	move_and_slide()
	_face_movement(delta)

func _state_idle() -> void:
	velocity.x = 0
	velocity.z = 0
	_target = _acquire_target()
	if _target:
		_state = State.CHASE

func _state_chase(delta: float) -> void:
	if _target == null or _is_target_invalid():
		_state = State.RETURN
		return
	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	# Leash: zu weit vom Spawn -> zurueckkehren.
	if global_position.distance_to(_spawn_pos) > data.leash_radius:
		_target = null
		_state = State.RETURN
		return
	if dist <= data.attack_range:
		velocity.x = 0
		velocity.z = 0
		_state = State.ATTACK
		return
	# Ranged: Abstand halten (Kiten), nicht komplett ranrennen.
	var desired_dist := data.attack_range * 0.8 if data.attack_style == EnemyData.AttackStyle.RANGED else 0.0
	if dist > desired_dist:
		var dir := to_target.normalized()
		velocity.x = dir.x * data.move_speed
		velocity.z = dir.z * data.move_speed

func _state_attack(delta: float) -> void:
	if _target == null or _is_target_invalid():
		_state = State.RETURN
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist > data.attack_range * 1.1:
		_state = State.CHASE
		return
	# Zum Ziel drehen bereits via _face_movement (nutzt velocity) -> hier direkt:
	_look_at_target(delta)
	velocity.x = 0
	velocity.z = 0
	if _attack_cd <= 0.0:
		_perform_attack()
		_attack_cd = data.attack_cooldown

func _state_return(delta: float) -> void:
	var to_spawn := _spawn_pos - global_position
	if to_spawn.length() < 0.5:
		velocity.x = 0
		velocity.z = 0
		# Regeneration beim Zurueckkehren (WoW-Leash-Heal).
		_health = data.max_health
		_update_health_bar()
		_state = State.IDLE
		return
	var dir := to_spawn.normalized()
	velocity.x = dir.x * data.move_speed
	velocity.z = dir.z * data.move_speed

func _perform_attack() -> void:
	if data.attack_style == EnemyData.AttackStyle.MELEE:
		if _target and _target.has_node("CombatSystem"):
			_target.get_node("CombatSystem").take_damage(data.damage, self)
		AudioManager.play_sfx("res://assets/audio/sfx_enemy_melee.ogg", -6.0)
	else:
		_fire_projectile()
		AudioManager.play_sfx("res://assets/audio/sfx_enemy_shoot.ogg", -6.0)

func _fire_projectile() -> void:
	var origin := global_position + Vector3.UP * 1.0
	var dir := (_target.global_position + Vector3.UP - origin).normalized()
	var proj := PoolManager.acquire("res://scenes/combat/projectile.tscn")
	get_parent().add_child(proj)
	proj.setup(origin, dir, data.damage, "player", self)

# ---------------------------------------------------------------------------
#  Ziel-Findung
# ---------------------------------------------------------------------------
func _acquire_target() -> Node3D:
	var player := get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) <= data.detection_radius:
		if not (player.has_method("is_dead") and player.is_dead()):
			return player
	return null

func _is_target_invalid() -> bool:
	if not is_instance_valid(_target):
		return true
	if _target.has_method("is_dead") and _target.is_dead():
		return true
	return false

# ---------------------------------------------------------------------------
#  Schaden / Tod
# ---------------------------------------------------------------------------
func take_damage(amount: int, source: Node = null) -> void:
	if _dead:
		return
	_health -= amount
	_update_health_bar()
	# Aggro auf Angreifer.
	if source and (_state == State.IDLE or _state == State.RETURN):
		_target = source
		_state = State.CHASE
	if _health <= 0:
		_die()

func _die() -> void:
	_dead = true
	_state = State.DEAD
	velocity = Vector3.ZERO
	# XP + Gold + Loot.
	Events.xp_gained.emit(data.xp_reward)
	var gold := randi_range(data.gold_min, data.gold_max)
	GameManager.character["gold"] += gold
	Events.gold_changed.emit(GameManager.character["gold"])
	Events.enemy_killed.emit(data, global_position)
	_drop_loot()
	AudioManager.play_sfx("res://assets/audio/sfx_enemy_death.ogg")
	# Kurze Todes-Verzoegerung, dann zurueck in Pool / freigeben.
	await get_tree().create_timer(0.3).timeout
	# Szene koennte inzwischen gewechselt haben (Menue/Neustart).
	if is_instance_valid(self):
		_return_to_pool()

func _drop_loot() -> void:
	for entry in data.loot_table:
		if randf() <= float(entry["chance"]):
			var amount := randi_range(int(entry.get("min", 1)), int(entry.get("max", 1)))
			_spawn_loot(StringName(entry["id"]), amount)

func _spawn_loot(item_id: StringName, amount: int) -> void:
	var loot := PoolManager.acquire("res://scenes/props/loot_drop.tscn")
	get_parent().add_child(loot)
	var offset := Vector3(randf_range(-1,1), 0.3, randf_range(-1,1))
	loot.setup(item_id, amount, global_position + offset)

func _return_to_pool() -> void:
	if get_meta("pool_path", "") != "":
		PoolManager.release(self)
	else:
		queue_free()

func is_dead() -> bool:
	return _dead

# ---------------------------------------------------------------------------
#  Darstellung
# ---------------------------------------------------------------------------
func _face_movement(delta: float) -> void:
	var flat := Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.2 and _mesh:
		var yaw := atan2(flat.x, flat.z)
		_mesh.rotation.y = lerp_angle(_mesh.rotation.y, yaw, 8.0 * delta)

func _look_at_target(delta: float) -> void:
	if _target == null or _mesh == null:
		return
	var to := _target.global_position - global_position
	to.y = 0
	if to.length() > 0.1:
		var yaw := atan2(to.x, to.z)
		_mesh.rotation.y = lerp_angle(_mesh.rotation.y, yaw, 8.0 * delta)

func _update_health_bar() -> void:
	if _health_bar and _health_bar.has_method("set_ratio"):
		_health_bar.set_ratio(float(_health) / float(maxi(1, data.max_health)))

func _on_onscreen() -> void:
	# Nur aktive Gegner (mit data) beim Sichtbarwerden wieder verarbeiten.
	if data != null and not _dead:
		set_physics_process(true)

func _on_offscreen() -> void:
	# Nur drosseln, wenn nicht im Kampf (sonst wuerde Gegner "einfrieren").
	if _state == State.IDLE:
		set_physics_process(false)

# --- Pool-Hooks ---
func _on_pool_acquire() -> void:
	_dead = false
	set_physics_process(true)
	visible = true
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", false)

func _on_pool_release() -> void:
	set_physics_process(false)
	_target = null
	# Aus der Ziel-Gruppe entfernen, solange inaktiv im Pool.
	if is_in_group("enemies"):
		remove_from_group("enemies")
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)
