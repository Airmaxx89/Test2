extends CanvasLayer
class_name DialogueUI

var panel: Panel
var content: VBoxContainer
var name_label: Label
var current_npc_id: String = ""


func _ready() -> void:
	layer = 7
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(640, 420)
	panel.size = Vector2(640, 420)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-320, -210)
	panel.visible = false
	add_child(panel)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	name_label.position = Vector2(20, 14)
	panel.add_child(name_label)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-140, 14)
	close_btn.pressed.connect(func(): panel.visible = false)
	panel.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 66)
	scroll.size = Vector2(600, 340)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(580, 0)
	content.add_theme_constant_override("separation", 10)
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
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 12))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)

		var tag := Label.new()
		tag.text = "Abschluss bereit"
		tag.add_theme_font_size_override("font_size", 14)
		tag.add_theme_color_override("font_color", GameTheme.XP_COLOR)
		box.add_child(tag)

		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.text = "%s\n%s\nBelohnung: %d EP, %d Münzen" % [q["title"], q["description"], q["xp_reward"], q["coin_reward"]]
		box.add_child(lbl)

		var btn := Button.new()
		btn.text = "Quest abschließen"
		btn.theme_type_variation = "PrimaryButton"
		btn.pressed.connect(_make_turnin_cb(quest_id))
		box.add_child(btn)
		content.add_child(card)

	var offers: Array = QuestManager.get_available_quests_for_npc(current_npc_id)
	for quest_id in offers:
		var q: Dictionary = QuestData.get_quest(quest_id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 12))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)

		var tag := Label.new()
		tag.text = "Neue Quest (Lvl %d)" % q["level"]
		tag.add_theme_font_size_override("font_size", 14)
		tag.add_theme_color_override("font_color", GameTheme.ACCENT)
		box.add_child(tag)

		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.text = "%s\n%s" % [q["title"], q["description"]]
		box.add_child(lbl)

		var btn := Button.new()
		btn.text = "Quest annehmen"
		btn.pressed.connect(_make_accept_cb(quest_id))
		box.add_child(btn)
		content.add_child(card)

	if turn_ins.is_empty() and offers.is_empty():
		var lbl := Label.new()
		lbl.text = "Ich habe im Moment nichts für dich."
		lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
		content.add_child(lbl)


func _make_accept_cb(quest_id: String) -> Callable:
	return func():
		QuestManager.start_quest(quest_id)
		_refresh()


func _make_turnin_cb(quest_id: String) -> Callable:
	return func():
		QuestManager.complete_quest(quest_id)
		_refresh()
