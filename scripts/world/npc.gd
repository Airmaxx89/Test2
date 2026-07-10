extends StaticBody3D
class_name NPC
## Quest-gebender NPC. Interagierbar (Gruppe "interactable").
## Zeigt bei Interaktion Dialog + bietet/abschliesst Quests basierend auf QuestTracker.
## Ueber der Figur schwebt ein Status-Indikator (! neue Quest, ? abgabebereit).

@export var npc_id: StringName = &"aldric"
@export var display_name: String = "NPC"
@export var body_color: Color = Color(0.3, 0.6, 0.4)

@onready var _mesh: Node3D = get_node_or_null("Body")
@onready var _indicator: Sprite3D = get_node_or_null("QuestIndicator")
@onready var _name_label: Label3D = get_node_or_null("NameLabel")

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("npc")
	# Auf den Interactable-Layer (6) legen, damit die Spieler-InteractionArea uns erkennt.
	collision_layer = 1 << 5
	collision_mask = 0
	if _name_label:
		_name_label.text = display_name
	if _mesh and _mesh.has_node("MeshInstance3D"):
		var mi: MeshInstance3D = _mesh.get_node("MeshInstance3D")
		var mat := StandardMaterial3D.new()
		mat.albedo_color = body_color
		mi.material_override = mat
	Events.quest_accepted.connect(func(_q): _refresh_indicator())
	Events.quest_completed.connect(func(_q): _refresh_indicator())
	Events.quest_ready_to_turnin.connect(func(_id): _refresh_indicator())
	Events.level_up.connect(func(_l): _refresh_indicator())
	call_deferred("_refresh_indicator")

## Von PlayerController.try_interact() aufgerufen.
func interact(_player: Node) -> void:
	# Prioritaet 1: abgabebereite Quest fuer diesen NPC.
	var turnin := _find_turnin_quest()
	if turnin != &"":
		var q := Database.get_quest(turnin)
		Events.show_dialog.emit(display_name, [q.completion_text])
		QuestTracker.turn_in_quest(turnin)
		_refresh_indicator()
		return
	# Prioritaet 2: TALK-Ziel einer aktiven Quest erfuellen.
	for qid in QuestTracker.active_quests():
		QuestTracker.report_objective(qid, QuestData.ObjectiveType.TALK, npc_id, 1)
	# Prioritaet 3: neue Quest anbieten.
	var offer := _find_available_quest()
	if offer != &"":
		var q := Database.get_quest(offer)
		Events.quest_offered.emit(q)          # UI zeigt Annehmen-Dialog
		_refresh_indicator()
		return
	# Sonst: Smalltalk.
	Events.show_dialog.emit(display_name, [_idle_line()])

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
			var turnin_npc: StringName = q.turnin_npc_id if q.turnin_npc_id != &"" else q.giver_npc_id
			if turnin_npc == npc_id:
				return qid
	return &""

func _refresh_indicator() -> void:
	if _indicator == null:
		return
	if _find_turnin_quest() != &"":
		_indicator.visible = true
		_indicator.modulate = Color(0.3, 1.0, 0.3)   # gruenes ? -> abgeben
		_set_indicator_text("?")
	elif _find_available_quest() != &"":
		_indicator.visible = true
		_indicator.modulate = Color(1.0, 0.85, 0.1)   # gelbes ! -> neue Quest
		_set_indicator_text("!")
	else:
		_indicator.visible = false

func _set_indicator_text(_t: String) -> void:
	# Falls der Indikator ein Label3D-Child statt Sprite nutzt.
	if _indicator.has_node("Text"):
		(_indicator.get_node("Text") as Label3D).text = _t

func _idle_line() -> String:
	var lines := [
		"Bleib wachsam da draussen.",
		"Die Ruinen sind kein Ort fuer Unvorbereitete.",
		"Moege dein Schwert scharf bleiben.",
	]
	return lines[randi() % lines.size()]
