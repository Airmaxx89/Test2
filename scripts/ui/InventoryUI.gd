extends CanvasLayer
class_name InventoryUI

var panel: Panel
var content: VBoxContainer
var is_visible_state: bool = false


func _ready() -> void:
	layer = 6
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(460, 600)
	panel.size = Vector2(460, 600)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-230, -300)
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "Inventar"
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
	scroll.size = Vector2(432, 520)
	panel.add_child(scroll)

	content = VBoxContainer.new()
	content.custom_minimum_size = Vector2(410, 0)
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
	for c in content.get_children():
		c.queue_free()

	var weapon_lbl := Label.new()
	var weapon_item: Dictionary = ItemData.get_item(GameManager.equipped_weapon)
	weapon_lbl.text = "Ausgerüstet: %s" % weapon_item.get("name", "-")
	content.add_child(weapon_lbl)
	content.add_child(HSeparator.new())

	for item_id in GameManager.inventory.keys():
		var item: Dictionary = ItemData.get_item(item_id)
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		var tex_path: String = item.get("icon", "")
		if tex_path != "":
			icon.texture = load(tex_path)
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(icon)
		var lbl := Label.new()
		lbl.text = " %s x%d" % [item.get("name", item_id), GameManager.inventory[item_id]]
		row.add_child(lbl)
		content.add_child(row)

	content.add_child(HSeparator.new())
	var gold_lbl := Label.new()
	gold_lbl.text = "Gold: %d Kupfermünzen" % GameManager.gold
	content.add_child(gold_lbl)
