extends CanvasLayer
class_name CharacterStatsUI
## Read-only character sheet: race/class, level/XP, the four attributes
## GameManager.get_stat() already computes, and the derived combat values
## (attack damage, max health/resource) - so the class-dependent balance fix
## in GameManager.get_attack_damage() is actually visible to the player.

var panel: Panel
var content: VBoxContainer


func _ready() -> void:
	layer = 6
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(440, 480)
	panel.size = Vector2(440, 480)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-220, -240)
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "Charakter"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	title.position = Vector2(20, 14)
	panel.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-140, 14)
	close_btn.pressed.connect(toggle)
	close_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 66)
	scroll.size = Vector2(400, 400)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(380, 0)
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	GameManager.health_changed.connect(func(_c, _m): _refresh())
	GameManager.resource_changed.connect(func(_c, _m): _refresh())
	GameManager.xp_changed.connect(func(_c, _n): _refresh())
	GameManager.level_changed.connect(func(_l): _refresh())


func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh()


func _refresh() -> void:
	for c in content.get_children():
		c.queue_free()

	var race: Dictionary = RaceData.RACES[GameManager.race_id]
	var cls: Dictionary = ClassData.CLASSES[GameManager.class_id]

	_add_card("%s - %s" % [race["name"], cls["name"]], "Level %d" % GameManager.level)
	_add_card("Erfahrung", "%d / %d EP" % [GameManager.xp, GameManager.xp_required(GameManager.level)])
	_add_card("Leben", "%d / %d" % [int(GameManager.health), int(GameManager.max_health)])
	_add_card(cls["resource_name"], "%d / %d" % [int(GameManager.resource), int(GameManager.max_resource)])
	_add_card("Angriffsschaden", "%d" % GameManager.get_attack_damage())

	var sep := Label.new()
	sep.text = "Attribute"
	sep.add_theme_color_override("font_color", GameTheme.ACCENT)
	content.add_child(sep)

	_add_card("Stärke", "%d" % GameManager.get_stat("strength"))
	_add_card("Beweglichkeit", "%d" % GameManager.get_stat("agility"))
	_add_card("Intellekt", "%d" % GameManager.get_stat("intellect"))
	_add_card("Ausdauer", "%d" % GameManager.get_stat("stamina"))


func _add_card(label_text: String, value_text: String) -> void:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 10))

	var hbox := HBoxContainer.new()
	row.add_child(hbox)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	hbox.add_child(val)

	content.add_child(row)
