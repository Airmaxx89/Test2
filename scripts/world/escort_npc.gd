extends CharacterBody3D
class_name EscortNPC
## Escort-Quest-NPC (z.B. Haendlerin Mira).
## Startet als normaler, interagierbarer Quest-NPC. Wird die Escort-Quest
## akzeptiert, folgt der NPC dem Spieler bis zum Zielpunkt; Ankunft schliesst
## das Escort-Ziel ab.

@export var npc_id: StringName = &"mira"
@export var display_name: String = "Haendlerin Mira"
@export var escort_quest_id: StringName = &"q_escort"
@export var body_color: Color = Color(0.7, 0.5, 0.3)
@export var destination_path: NodePath          # Zielmarker (Node3D) in der Welt
@export var follow_distance := 3.0
@export var move_speed := 4.0
@export var arrive_radius := 3.0

enum Mode { STATIONARY, FOLLOWING, ARRIVED }
var _mode: Mode = Mode.STATIONARY
var _destination: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 18.0)

@onready var _mesh: Node3D = get_node_or_null("Body")
@onready var _name_label: Label3D = get_node_or_null("NameLabel")
@onready var _indicator: Sprite3D = get_node_or_null("QuestIndicator")

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	# Interactable-Layer (6) zum Erkennen durch die Spieler-InteractionArea;
	# Mask 1 (world) fuer Bodenkollision/Gravitation beim Folgen.
	collision_layer = 1 << 5
	collision_mask = (1 << 0)
	if _name_label:
		_name_label.text = display_name
	if destination_path:
		_destination = get_node_or_null(destination_path)
	if _mesh and _mesh.has_node("MeshInstance3D"):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = body_color
		(_mesh.get_node("MeshInstance3D") as MeshInstance3D).material_override = mat
	Events.quest_accepted.connect(_on_quest_accepted)
	call_deferred("_refresh_indicator")

func _on_quest_accepted(q: QuestData) -> void:
	if q.id == escort_quest_id:
		_mode = Mode.FOLLOWING
		Events.toast_message.emit("%s folgt dir jetzt." % display_name)
		if _indicator:
			_indicator.visible = false

func interact(_player: Node) -> void:
	# Offer / turn-in wie bei normalem NPC (fuer die Escort-Quest selbst).
	if QuestTracker.get_state(escort_quest_id) == QuestTracker.State.READY_TO_TURNIN:
		var q := Database.get_quest(escort_quest_id)
		Events.show_dialog.emit(display_name, [q.completion_text])
		QuestTracker.turn_in_quest(escort_quest_id)
		_refresh_indicator()
		return
	if QuestTracker.is_available(escort_quest_id) and GameManager.character["level"] >= Database.get_quest(escort_quest_id).required_level:
		Events.quest_offered.emit(Database.get_quest(escort_quest_id))
		return
	# Weitere Quests dieses NPCs (q_herbs, q_bandits) ueber generische Logik:
	var offer := _find_available_quest()
	if offer != &"":
		Events.quest_offered.emit(Database.get_quest(offer))
		return
	var turnin := _find_turnin_quest()
	if turnin != &"":
		var q := Database.get_quest(turnin)
		Events.show_dialog.emit(display_name, [q.completion_text])
		QuestTracker.turn_in_quest(turnin)
		_refresh_indicator()
		return
	Events.show_dialog.emit(display_name, ["Sei vorsichtig da draussen, Reisender."])

func _physics_process(delta: float) -> void:
	if _mode != Mode.FOLLOWING:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var player := get_tree().get_first_node_in_group("player")
	# Ziel erreicht?
	if _destination and global_position.distance_to(_destination.global_position) <= arrive_radius:
		_arrive()
		return
	# Dem Spieler folgen (aber Abstand halten).
	if player:
		var to := player.global_position - global_position
		to.y = 0
		if to.length() > follow_distance:
			var dir := to.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			if _mesh:
				_mesh.rotation.y = lerp_angle(_mesh.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
		else:
			velocity.x = 0
			velocity.z = 0
	move_and_slide()

func _arrive() -> void:
	_mode = Mode.ARRIVED
	velocity = Vector3.ZERO
	QuestTracker.report_objective(escort_quest_id, QuestData.ObjectiveType.ESCORT, npc_id, 1)
	Events.toast_message.emit("%s ist sicher angekommen!" % display_name)
	_refresh_indicator()

# --- gemeinsame Quest-Helfer (analog NPC) ---
func _find_available_quest() -> StringName:
	for q in Database.all_quests():
		if q.giver_npc_id == npc_id and QuestTracker.is_available(q.id):
			if GameManager.character["level"] >= q.required_level:
				return q.id
	return &""

func _find_turnin_quest() -> StringName:
	for qid in QuestTracker.active_quests():
		if QuestTracker.get_state(qid) == QuestTracker.State.READY_TO_TURNIN:
			var q := Database.get_quest(qid)
			var t: StringName = q.turnin_npc_id if q.turnin_npc_id != &"" else q.giver_npc_id
			if t == npc_id:
				return qid
	return &""

func _refresh_indicator() -> void:
	if _indicator == null:
		return
	_indicator.visible = _find_available_quest() != &"" or _find_turnin_quest() != &""
