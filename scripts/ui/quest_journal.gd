extends Control
class_name QuestJournal
## Quest-Journal (Vollbild-Panel, per Button/Taste umschaltbar).
## Listet aktive & abgeschlossene Quests mit Zielen und Belohnungen.

@onready var _active_list: VBoxContainer = $Panel/VBox/HBox/Left/Scroll/ActiveList
@onready var _detail: RichTextLabel = $Panel/VBox/HBox/Right/Detail
@onready var _close_btn: Button = $Panel/VBox/Header/CloseButton

func _ready() -> void:
	visible = false
	_close_btn.pressed.connect(hide_journal)
	Events.quest_accepted.connect(func(_q): if visible: _refresh())
	Events.quest_objective_updated.connect(func(_a,_b,_c,_d): if visible: _refresh())
	Events.quest_completed.connect(func(_q): if visible: _refresh())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle()

func toggle() -> void:
	if visible:
		hide_journal()
	else:
		show_journal()

func show_journal() -> void:
	visible = true
	_refresh()

func hide_journal() -> void:
	visible = false

func _refresh() -> void:
	for c in _active_list.get_children():
		c.queue_free()
	_detail.text = "Waehle eine Quest aus der Liste."

	# Aktive & abgabebereite Quests.
	for qid in QuestTracker.active_quests():
		_add_quest_button(qid, false)
	# Abgeschlossene.
	for qid in QuestTracker.quest_states:
		if QuestTracker.is_completed(qid):
			_add_quest_button(qid, true)

func _add_quest_button(qid: StringName, completed: bool) -> void:
	var q := Database.get_quest(qid)
	if q == null:
		return
	var btn := Button.new()
	var prefix := "[X] " if completed else ("[!] " if QuestTracker.get_state(qid) == QuestTracker.State.READY_TO_TURNIN else "[ ] ")
	btn.text = prefix + q.title
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(_show_detail.bind(qid))
	_active_list.add_child(btn)

func _show_detail(qid: StringName) -> void:
	var q := Database.get_quest(qid)
	if q == null:
		return
	var progress := QuestTracker.get_progress(qid)
	var s := "[b]%s[/b]\n\n%s\n\n[b]Ziele:[/b]\n" % [q.title, q.summary]
	for i in q.objectives.size():
		var obj: Dictionary = q.objectives[i]
		var done: int = progress[i] if i < progress.size() else 0
		var total: int = int(obj["amount"])
		var mark := "[color=green]v[/color]" if done >= total else "-"
		s += "%s %s: %d/%d\n" % [mark, obj["label"], done, total]
	s += "\n[b]Belohnung:[/b]\n"
	s += "%d XP, %d Gold\n" % [q.reward_xp, q.reward_gold]
	for item in q.reward_items:
		var it := Database.get_item(StringName(item["id"]))
		if it:
			s += "%s x%d\n" % [it.display_name, int(item["amount"])]
	_detail.text = s
