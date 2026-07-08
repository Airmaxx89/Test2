extends CanvasLayer
class_name CharacterCreationUI

signal character_confirmed(race_id: String, class_id: String)

var selected_race: String = "mensch"
var selected_class: String = "krieger"
var race_buttons: Dictionary = {}
var class_buttons: Dictionary = {}
var info_label: Label


func _ready() -> void:
	layer = 20
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.06, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Charaktererstellung"
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-200, 60)
	title.size = Vector2(400, 50)
	bg.add_child(title)

	var race_label := Label.new()
	race_label.text = "Volk wählen:"
	race_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	race_label.position = Vector2(-200, 140)
	race_label.size = Vector2(400, 30)
	bg.add_child(race_label)

	var race_ids: Array = RaceData.get_race_ids()
	for i in range(race_ids.size()):
		var rid: String = race_ids[i]
		var b := Button.new()
		b.text = RaceData.RACES[rid]["name"]
		b.custom_minimum_size = Vector2(150, 60)
		b.toggle_mode = true
		b.button_pressed = (rid == "mensch")
		b.set_anchors_preset(Control.PRESET_CENTER_TOP)
		b.position = Vector2(-240 + i * 160, 180)
		b.pressed.connect(_make_race_cb(rid))
		bg.add_child(b)
		race_buttons[rid] = b

	var class_label := Label.new()
	class_label.text = "Klasse wählen:"
	class_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	class_label.position = Vector2(-200, 270)
	class_label.size = Vector2(400, 30)
	bg.add_child(class_label)

	var class_ids: Array = ClassData.get_class_ids()
	for i in range(class_ids.size()):
		var cid: String = class_ids[i]
		var b := Button.new()
		b.text = ClassData.CLASSES[cid]["name"]
		b.custom_minimum_size = Vector2(150, 60)
		b.toggle_mode = true
		b.button_pressed = (cid == "krieger")
		b.set_anchors_preset(Control.PRESET_CENTER_TOP)
		b.position = Vector2(-240 + i * 160, 310)
		b.pressed.connect(_make_class_cb(cid))
		bg.add_child(b)
		class_buttons[cid] = b

	info_label = Label.new()
	info_label.set_anchors_preset(Control.PRESET_CENTER)
	info_label.position = Vector2(-220, -20)
	info_label.size = Vector2(440, 140)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	bg.add_child(info_label)
	_update_info()

	var start_btn := Button.new()
	start_btn.text = "Abenteuer beginnen"
	start_btn.custom_minimum_size = Vector2(280, 70)
	start_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	start_btn.position = Vector2(-140, -120)
	start_btn.pressed.connect(func(): character_confirmed.emit(selected_race, selected_class))
	bg.add_child(start_btn)


func _make_race_cb(rid: String) -> Callable:
	return func():
		selected_race = rid
		for id in race_buttons.keys():
			race_buttons[id].button_pressed = (id == rid)
		_update_info()


func _make_class_cb(cid: String) -> Callable:
	return func():
		selected_class = cid
		for id in class_buttons.keys():
			class_buttons[id].button_pressed = (id == cid)
		_update_info()


func _update_info() -> void:
	var race: Dictionary = RaceData.RACES[selected_race]
	var cls: Dictionary = ClassData.CLASSES[selected_class]
	info_label.text = "%s - %s\n%s\n%s" % [race["name"], cls["name"], race["description"], cls["description"]]
