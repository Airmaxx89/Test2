extends CanvasLayer
class_name QuestLogUI

var panel: Panel
var content: VBoxContainer
var is_visible_state: bool = false


func _ready() -> void:
	layer = 6
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(620, 560)
	panel.size = Vector2(620, 560)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-310, -280)
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "Questlog"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	title.position = Vector2(20, 14)
	panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-140, 14)
	close_btn.pressed.connect(func(): toggle())
	panel.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 68)
	scroll.size = Vector2(580, 476)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(560, 0)
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	QuestManager.quest_started.connect(func(_id): _refresh())
	QuestManager.quest_updated.connect(func(_id): _refresh())
	QuestManager.quest_completed.connect(func(_id): _refresh())
	_refresh()


func toggle() -> void:
	is_visible_state = not is_visible_state
	panel.visible = is_visible_state
	if is_visible_state:
		_refresh()


func _refresh() -> void:
	for c in content.get_children():
		c.queue_free()

	if QuestManager.active_quests.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Noch keine aktiven Quests. Sprich mit den Dorfbewohnern von Eichenfeld."
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		empty_lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
		content.add_child(empty_lbl)

	for quest_id in QuestManager.active_quests.keys():
		var q: Dictionary = QuestData.get_quest(quest_id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 12))
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		card.add_child(vbox)

		var title_lbl := Label.new()
		title_lbl.text = "%s (Lvl %d)" % [q["title"], q["level"]]
		title_lbl.add_theme_color_override("font_color", GameTheme.ACCENT)
		title_lbl.add_theme_font_size_override("font_size", 20)
		vbox.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = q["description"]
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
		vbox.add_child(desc_lbl)

		for i in range(q["objectives"].size()):
			var obj: Dictionary = q["objectives"][i]
			var progress: int = QuestManager.get_objective_progress(quest_id, i)
			var done: bool = progress >= obj["count"]
			var obj_lbl := Label.new()
			obj_lbl.text = "%s %s: %d/%d" % ["✓" if done else "-", _objective_label(obj), progress, obj["count"]]
			obj_lbl.add_theme_font_size_override("font_size", 16)
			obj_lbl.add_theme_color_override("font_color", GameTheme.XP_COLOR if done else GameTheme.TEXT)
			vbox.add_child(obj_lbl)

		content.add_child(card)

	var done_lbl := Label.new()
	done_lbl.text = "Abgeschlossene Quests: %d / %d" % [QuestManager.completed_quests.size(), QuestData.QUESTS.size()]
	done_lbl.add_theme_color_override("font_color", GameTheme.ACCENT)
	content.add_child(done_lbl)


func _objective_label(obj: Dictionary) -> String:
	match obj["type"]:
		"kill":
			var mob: Dictionary = MobData.get_mob(obj["target"])
			return "Besiege %s" % mob.get("name", "Gegner")
		"collect":
			var item: Dictionary = ItemData.get_item(obj["target"])
			return "Sammle %s" % item.get("name", obj["target"])
		"reach":
			return "Erreiche den Ort"
		_:
			return "Ziel"
