extends CanvasLayer
class_name DialogueUI

var panel: Panel
var content: VBoxContainer
var name_label: Label
var current_npc_id: String = ""


func _ready() -> void:
	layer = 7
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(560, 420)
	panel.size = Vector2(560, 420)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-280, -210)
	panel.visible = false
	add_child(panel)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.position = Vector2(14, 10)
	panel.add_child(name_label)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-140, 10)
	close_btn.pressed.connect(func(): panel.visible = false)
	panel.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 60)
	scroll.size = Vector2(530, 350)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(510, 0)
	scroll.add_child(content)

	DialogueState.npc_interacted.connect(_on_npc_interacted)


func _on_npc_interacted(npc_id: String, npc_name: String) -> void:
	current_npc_id = npc_id
	name_label.text = npc_name
	panel.visible = true
	_refresh()


func _refresh() -> void:
	for c in content.get_children():
		c.queue_free()

	var turn_ins: Array = QuestManager.get_turn_in_quests_for_npc(current_npc_id)
	for quest_id in turn_ins:
		var q: Dictionary = QuestData.get_quest(quest_id)
		var box := VBoxContainer.new()
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.text = "[Abschluss bereit] %s\n%s\nBelohnung: %d EP, %d Münzen" % [q["title"], q["description"], q["xp_reward"], q["coin_reward"]]
		box.add_child(lbl)
		var btn := Button.new()
		btn.text = "Quest abschließen"
		btn.pressed.connect(_make_turnin_cb(quest_id))
		box.add_child(btn)
		content.add_child(box)
		content.add_child(HSeparator.new())

	var offers: Array = QuestManager.get_available_quests_for_npc(current_npc_id)
	for quest_id in offers:
		var q: Dictionary = QuestData.get_quest(quest_id)
		var box := VBoxContainer.new()
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.text = "[Neue Quest] %s (Lvl %d)\n%s" % [q["title"], q["level"], q["description"]]
		box.add_child(lbl)
		var btn := Button.new()
		btn.text = "Quest annehmen"
		btn.pressed.connect(_make_accept_cb(quest_id))
		box.add_child(btn)
		content.add_child(box)
		content.add_child(HSeparator.new())

	if turn_ins.is_empty() and offers.is_empty():
		var lbl := Label.new()
		lbl.text = "Ich habe im Moment nichts für dich."
		content.add_child(lbl)


func _make_accept_cb(quest_id: String) -> Callable:
	return func():
		QuestManager.start_quest(quest_id)
		_refresh()


func _make_turnin_cb(quest_id: String) -> Callable:
	return func():
		QuestManager.complete_quest(quest_id)
		_refresh()
