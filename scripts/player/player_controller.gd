extends CharacterBody3D
class_name PlayerController
## Spieler-Steuerung fuer Third-Person-Movement.
## Input-Quellen:
##   1) Virtueller Joystick (Touch)  -> input_vector (via set_move_input)
##   2) Tastatur (WASD)              -> Fallback/Desktop-Test
## Bewegung ist kamerarelativ. Rotation folgt Bewegungsrichtung.
##
## Kind-Nodes (per Szene): CombatSystem, InventorySystem, LevelingSystem,
## InteractionArea (Area3D), MeshInstance3D (Platzhalter-Koerper).

@export var move_speed := 5.0
@export var sprint_multiplier := 1.6
@export var rotation_speed := 12.0
@export var jump_velocity := 6.5

var _input_vector := Vector2.ZERO      # von Joystick (x=rechts, y=vorne)
var _sprinting := false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)

@onready var camera_rig: Node3D = get_node_or_null("../CameraRig")
@onready var combat: CombatSystem = $CombatSystem
@onready var mesh: Node3D = $Body
@onready var interaction_area: Area3D = $InteractionArea

var _current_interactable: Node = null
var _dead := false

func _ready() -> void:
	add_to_group("player")
	# Kollisions-Layer/Mask: Player=Layer2, kollidiert mit World+Enemy.
	collision_layer = 1 << 1
	collision_mask = (1 << 0) | (1 << 2)
	# Spawn-Position aus Save/GameManager.
	var spawn: Vector3 = GameManager.character.get("spawn_position", Vector3.ZERO)
	if spawn != Vector3.ZERO:
		global_position = spawn
	# Optik nach Klasse einfaerben.
	_apply_class_appearance()
	# Interaktions-Erkennung.
	interaction_area.body_entered.connect(_on_interact_body_entered)
	interaction_area.area_entered.connect(_on_interact_area_entered)
	interaction_area.body_exited.connect(_on_interact_exited)
	interaction_area.area_exited.connect(_on_interact_exited)
	combat.died.connect(_on_died)
	# Systeme melden sich an; GameManager kennt jetzt den Spieler.
	GameManager.player = self
	Events.player_ready.emit(self)

func _apply_class_appearance() -> void:
	var cls := GameManager.get_class_data()
	if cls and mesh.has_node("MeshInstance3D"):
		var mi: MeshInstance3D = mesh.get_node("MeshInstance3D")
		var mat := StandardMaterial3D.new()
		mat.albedo_color = cls.body_color
		mi.material_override = mat

# ---------------------------------------------------------------------------
#  Input-API (vom HUD / Joystick aufgerufen)
# ---------------------------------------------------------------------------
func set_move_input(vec: Vector2) -> void:
	_input_vector = vec

func set_sprint(active: bool) -> void:
	_sprinting = active

func do_jump() -> void:
	if is_on_floor() and not _dead:
		velocity.y = jump_velocity

func try_interact() -> void:
	if _current_interactable and is_instance_valid(_current_interactable):
		if _current_interactable.has_method("interact"):
			_current_interactable.interact(self)

# ---------------------------------------------------------------------------
#  Bewegung
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector3.ZERO
		return

	# Tastatur-Fallback mischen (Desktop-Test).
	var kb := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var raw := _input_vector
	if kb.length() > 0.1:
		raw = Vector2(kb.x, -kb.y)   # move_forward -> +y (vorne)
	# Sprint aus Touch-Button (_sprinting) ODER Tastatur — ohne _sprinting zu mutieren.
	var sprint_held := _sprinting or Input.is_action_pressed("sprint")

	# Schwerkraft.
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Kamerarelative Richtung berechnen.
	var move_dir := Vector3.ZERO
	if raw.length() > 0.1:
		var cam_basis := _get_camera_basis()
		move_dir = (cam_basis.x * raw.x) + (-cam_basis.z * raw.y)
		move_dir.y = 0
		move_dir = move_dir.normalized()

	var speed := move_speed * (sprint_multiplier if sprint_held else 1.0)
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed

	# Modell in Bewegungsrichtung drehen (weich).
	if move_dir.length() > 0.1:
		var target_yaw := atan2(move_dir.x, move_dir.z)
		mesh.rotation.y = lerp_angle(mesh.rotation.y, target_yaw, rotation_speed * delta)

	move_and_slide()

func _get_camera_basis() -> Basis:
	# Die Kamera-Gierung (Yaw) liegt im CameraRig-Skript, nicht auf der Rig-Wurzel.
	# Daher Bewegungs-Basis aus dem Yaw-Winkel konstruieren -> Bewegung ist
	# korrekt relativ zur Blickrichtung der Kamera.
	if camera_rig and camera_rig.has_method("get_yaw"):
		return Basis(Vector3.UP, camera_rig.get_yaw())
	return global_transform.basis

# ---------------------------------------------------------------------------
#  Interaktion
# ---------------------------------------------------------------------------
func _on_interact_body_entered(body: Node) -> void:
	_register_interactable(body)

func _on_interact_area_entered(area: Node) -> void:
	_register_interactable(area)

func _register_interactable(node: Node) -> void:
	if node.is_in_group("interactable"):
		_current_interactable = node
		Events.interactable_in_range.emit(node)

func _on_interact_exited(node: Node) -> void:
	if node == _current_interactable:
		_current_interactable = null
		Events.interactable_out_of_range.emit(node)

# ---------------------------------------------------------------------------
#  Tod / Respawn
# ---------------------------------------------------------------------------
func _on_died() -> void:
	_dead = true
	Events.toast_message.emit("Du wurdest besiegt... Respawn am Dorf.")
	# Kurze Verzoegerung, dann am Spawn wiederbeleben (Prototyp-Respawn).
	await get_tree().create_timer(2.0).timeout
	_respawn()

func _respawn() -> void:
	_dead = false
	var stats: Dictionary = GameManager.character["stats"]
	GameManager.character["current_health"] = stats.get(&"max_health", 1)
	GameManager.character["current_mana"] = stats.get(&"max_mana", 1)
	Events.player_healed.emit(0, GameManager.character["current_health"], stats.get(&"max_health", 1))
	Events.player_mana_changed.emit(GameManager.character["current_mana"], stats.get(&"max_mana", 1))
	global_position = GameManager.character.get("spawn_position", Vector3.ZERO) + Vector3.UP
	velocity = Vector3.ZERO

func is_dead() -> bool:
	return _dead
