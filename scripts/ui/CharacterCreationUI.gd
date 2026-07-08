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
	var bg := TextureRect.new()
	bg.texture = GameTheme.background_texture(Color(0.09, 0.12, 0.09, 1), Color(0.05, 0.04, 0.03, 1))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)

	var title := Label.new()
	title.text = "Charaktererstellung"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-200, 24)
	title.size = Vector2(400, 46)
	bg.add_child(title)

	# Left column: Volk (race)
	var race_panel := Panel.new()
	race_panel.custom_minimum_size = Vector2(360, 260)
	race_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	race_panel.position = Vector2(40, -130)
	bg.add_child(race_panel)

	var race_label := Label.new()
	race_label.text = "Volk"
	race_label.add_theme_font_size_override("font_size", 22)
	race_label.add_theme_color_override("font_color", GameTheme.ACCENT)
	race_label.position = Vector2(20, 14)
	race_panel.add_child(race_label)

	var race_ids: Array = RaceData.get_race_ids()
	for i in range(race_ids.size()):
		var rid: String = race_ids[i]
		var b := Button.new()
		b.text = RaceData.RACES[rid]["name"]
		b.custom_minimum_size = Vector2(320, 60)
		b.toggle_mode = true
		b.button_pressed = (rid == "mensch")
		b.position = Vector2(20, 56 + i * 68)
		b.pressed.connect(_make_race_cb(rid))
		race_panel.add_child(b)
		race_buttons[rid] = b

	# Right column: Klasse
	var class_panel := Panel.new()
	class_panel.custom_minimum_size = Vector2(360, 260)
	class_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	class_panel.position = Vector2(-400, -130)
	bg.add_child(class_panel)

	var class_label := Label.new()
	class_label.text = "Klasse"
	class_label.add_theme_font_size_override("font_size", 22)
	class_label.add_theme_color_override("font_color", GameTheme.ACCENT)
	class_label.position = Vector2(20, 14)
	class_panel.add_child(class_label)

	var class_ids: Array = ClassData.get_class_ids()
	for i in range(class_ids.size()):
		var cid: String = class_ids[i]
		var b := Button.new()
		b.text = ClassData.CLASSES[cid]["name"]
		b.custom_minimum_size = Vector2(320, 60)
		b.toggle_mode = true
		b.button_pressed = (cid == "krieger")
		b.position = Vector2(20, 56 + i * 68)
		b.pressed.connect(_make_class_cb(cid))
		class_panel.add_child(b)
		class_buttons[cid] = b

	# Center: description panel
	var info_panel := Panel.new()
	info_panel.custom_minimum_size = Vector2(440, 160)
	info_panel.set_anchors_preset(Control.PRESET_CENTER)
	info_panel.position = Vector2(-220, -80)
	bg.add_child(info_panel)

	info_label = Label.new()
	info_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_panel.add_child(info_label)
	_update_info()

	var start_btn := Button.new()
	start_btn.text = "Abenteuer beginnen"
	start_btn.theme_type_variation = "PrimaryButton"
	start_btn.custom_minimum_size = Vector2(300, 68)
	start_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	start_btn.position = Vector2(-150, -92)
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
