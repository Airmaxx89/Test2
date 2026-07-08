extends CanvasLayer
class_name QuestLogUI

var panel: Panel
var content: VBoxContainer
var is_visible_state: bool = false


func _ready() -> void:
	layer = 6
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(520, 720)
	panel.size = Vector2(520, 720)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -360)
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "Questlog"
	title.add_theme_font_size_override("font_size", 26)
	title.position = Vector2(14, 10)
	panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-140, 10)
	close_btn.pressed.connect(func(): toggle())
	panel.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(14, 64)
	scroll.size = Vector2(492, 640)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(470, 0)
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
		content.add_child(empty_lbl)

	for quest_id in QuestManager.active_quests.keys():
		var q: Dictionary = QuestData.get_quest(quest_id)
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		var text: String = "%s (Lvl %d)\n%s\n" % [q["title"], q["level"], q["description"]]
		for i in range(q["objectives"].size()):
			var obj: Dictionary = q["objectives"][i]
			var progress: int = QuestManager.get_objective_progress(quest_id, i)
			text += "- %s: %d/%d\n" % [_objective_label(obj), progress, obj["count"]]
		lbl.text = text
		content.add_child(lbl)
		content.add_child(HSeparator.new())

	var done_lbl := Label.new()
	done_lbl.text = "Abgeschlossene Quests: %d / %d" % [QuestManager.completed_quests.size(), QuestData.QUESTS.size()]
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
