extends CanvasLayer
class_name InventoryUI

var panel: Panel
var content: VBoxContainer
var weapon_lbl: Label
var gold_lbl: Label
var is_visible_state: bool = false


func _ready() -> void:
	layer = 6
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(480, 540)
	panel.size = Vector2(480, 540)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-240, -270)
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "Inventar"
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
	close_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(close_btn)

	var weapon_card := PanelContainer.new()
	weapon_card.position = Vector2(20, 66)
	weapon_card.size = Vector2(440, 0)
	weapon_card.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 12))
	panel.add_child(weapon_card)

	weapon_lbl = Label.new()
	weapon_lbl.add_theme_color_override("font_color", GameTheme.ACCENT)
	weapon_card.add_child(weapon_lbl)

	var gold_card := PanelContainer.new()
	gold_card.position = Vector2(20, 122)
	gold_card.size = Vector2(440, 0)
	gold_card.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 12))
	panel.add_child(gold_card)

	gold_lbl = Label.new()
	gold_lbl.add_theme_color_override("font_color", GameTheme.XP_COLOR)
	gold_card.add_child(gold_lbl)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 182)
	scroll.size = Vector2(440, 340)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(420, 0)
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	GameManager.inventory_changed.connect(_refresh)
	GameManager.gold_changed.connect(func(_amount): _refresh())
	_refresh()


func toggle() -> void:
	is_visible_state = not is_visible_state
	panel.visible = is_visible_state
	if is_visible_state:
		_refresh()


func _refresh() -> void:
	var weapon_item: Dictionary = ItemData.get_item(GameManager.equipped_weapon)
	weapon_lbl.text = "Ausgerüstet: %s" % weapon_item.get("name", "-")
	gold_lbl.text = "Gold: %d Kupfermünzen" % GameManager.gold

	for c in content.get_children():
		c.queue_free()

	if GameManager.inventory.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Dein Beutel ist leer."
		empty_lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
		content.add_child(empty_lbl)
		return

	for item_id in GameManager.inventory.keys():
		var item: Dictionary = ItemData.get_item(item_id)
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 10))

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row.add_child(hbox)

		var icon := TextureRect.new()
		var tex_path: String = item.get("icon", "")
		if tex_path != "":
			icon.texture = load(tex_path)
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hbox.add_child(icon)

		var lbl := Label.new()
		lbl.text = "%s  x%d" % [item.get("name", item_id), GameManager.inventory[item_id]]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		if item.get("type", "") == "consumable":
			var use_btn := Button.new()
			use_btn.text = "Benutzen"
			use_btn.custom_minimum_size = Vector2(110, 40)
			use_btn.pressed.connect(_make_use_cb(item_id))
			hbox.add_child(use_btn)
		elif item.get("type", "") == "weapon" and item_id != GameManager.equipped_weapon:
			var equip_btn := Button.new()
			equip_btn.text = "Ausrüsten"
			equip_btn.custom_minimum_size = Vector2(110, 40)
			equip_btn.disabled = item.get("class_restriction", "") != GameManager.class_id
			equip_btn.pressed.connect(_make_equip_cb(item_id))
			hbox.add_child(equip_btn)

		content.add_child(row)


func _make_use_cb(item_id: String) -> Callable:
	return func():
		GameManager.use_consumable(item_id)
		AudioManager.play_sfx("button_click")


func _make_equip_cb(item_id: String) -> Callable:
	return func():
		GameManager.equip_weapon(item_id)
		AudioManager.play_sfx("button_click")
		_refresh()
