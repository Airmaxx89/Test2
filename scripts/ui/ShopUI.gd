extends CanvasLayer
class_name ShopUI
## Simple buy/sell screen opened by vendor NPCs (ZoneData "vendor": true).
## "Kaufen" lists the NPC's fixed shop_items at a markup over their
## sell_value; "Verkaufen" lists the player's own sellable inventory - this
## finally gives Gold a purpose beyond mob loot/quest rewards.

const BUY_PRICE_MULTIPLIER := 3

var panel: Panel
var name_label: Label
var gold_label: Label
var buy_content: VBoxContainer
var sell_content: VBoxContainer
var current_npc_id: String = ""


func _ready() -> void:
	layer = 7
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(680, 480)
	panel.size = Vector2(680, 480)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-340, -240)
	panel.visible = false
	add_child(panel)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	name_label.position = Vector2(20, 14)
	panel.add_child(name_label)

	gold_label = Label.new()
	gold_label.add_theme_color_override("font_color", GameTheme.XP_COLOR)
	gold_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	gold_label.position = Vector2(-260, 18)
	gold_label.size = Vector2(140, 30)
	panel.add_child(gold_label)

	var close_btn := Button.new()
	close_btn.text = "Schließen"
	close_btn.custom_minimum_size = Vector2(120, 44)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.position = Vector2(-140, 14)
	close_btn.pressed.connect(func(): panel.visible = false)
	close_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(close_btn)

	var buy_title := Label.new()
	buy_title.text = "Kaufen"
	buy_title.position = Vector2(20, 62)
	buy_title.add_theme_color_override("font_color", GameTheme.ACCENT)
	panel.add_child(buy_title)

	var buy_scroll := ScrollContainer.new()
	buy_scroll.position = Vector2(20, 100)
	buy_scroll.size = Vector2(300, 350)
	panel.add_child(buy_scroll)

	buy_content = VBoxContainer.new()
	buy_content.custom_minimum_size = Vector2(280, 0)
	buy_content.add_theme_constant_override("separation", 8)
	buy_scroll.add_child(buy_content)

	var sell_title := Label.new()
	sell_title.text = "Verkaufen"
	sell_title.position = Vector2(340, 62)
	sell_title.add_theme_color_override("font_color", GameTheme.ACCENT)
	panel.add_child(sell_title)

	var sell_scroll := ScrollContainer.new()
	sell_scroll.position = Vector2(340, 100)
	sell_scroll.size = Vector2(320, 350)
	panel.add_child(sell_scroll)

	sell_content = VBoxContainer.new()
	sell_content.custom_minimum_size = Vector2(300, 0)
	sell_content.add_theme_constant_override("separation", 8)
	sell_scroll.add_child(sell_content)

	DialogueState.shop_requested.connect(_on_shop_requested)
	GameManager.gold_changed.connect(func(_amount): _refresh())
	GameManager.inventory_changed.connect(_refresh)


func _on_shop_requested(npc_id: String, npc_name: String) -> void:
	current_npc_id = npc_id
	name_label.text = npc_name
	panel.visible = true
	_refresh()


func _refresh() -> void:
	gold_label.text = "%d Gold" % GameManager.gold
	for c in buy_content.get_children():
		c.queue_free()
	for c in sell_content.get_children():
		c.queue_free()

	var npc_def: Dictionary = ZoneData.get_npc(current_npc_id)
	var shop_items: Array = npc_def.get("shop_items", [])
	for item_id in shop_items:
		var item: Dictionary = ItemData.get_item(item_id)
		var price: int = int(item.get("sell_value", 1)) * BUY_PRICE_MULTIPLIER
		buy_content.add_child(_make_row(item, "%d Gold" % price, "Kaufen", _make_buy_cb(item_id, price)))

	if shop_items.is_empty():
		var lbl := Label.new()
		lbl.text = "Nichts im Angebot."
		lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
		buy_content.add_child(lbl)

	var sellable := false
	for item_id in GameManager.inventory.keys():
		var item: Dictionary = ItemData.get_item(item_id)
		var value: int = int(item.get("sell_value", 0))
		if value <= 0:
			continue
		sellable = true
		var count: int = GameManager.inventory[item_id]
		sell_content.add_child(_make_row(item, "%d Gold  (x%d)" % [value, count], "Verkaufen", _make_sell_cb(item_id)))

	if not sellable:
		var lbl := Label.new()
		lbl.text = "Du hast nichts Verkäufliches dabei."
		lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
		sell_content.add_child(lbl)


func _make_row(item: Dictionary, price_text: String, action_text: String, cb: Callable) -> PanelContainer:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", GameTheme.panel_style(GameTheme.BG_PANEL_LIGHT, 10))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)

	var icon := TextureRect.new()
	var tex_path: String = item.get("icon", "")
	if tex_path != "":
		icon.texture = load(tex_path)
	icon.custom_minimum_size = Vector2(30, 30)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = item.get("name", "?")
	name_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_lbl)

	var price_lbl := Label.new()
	price_lbl.text = price_text
	price_lbl.add_theme_font_size_override("font_size", 14)
	price_lbl.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
	vbox.add_child(price_lbl)

	var action_btn := Button.new()
	action_btn.text = action_text
	action_btn.custom_minimum_size = Vector2(100, 40)
	action_btn.pressed.connect(cb)
	hbox.add_child(action_btn)

	return row


func _make_buy_cb(item_id: String, price: int) -> Callable:
	return func():
		if GameManager.spend_gold(price):
			GameManager.add_item(item_id, 1)
			AudioManager.play_sfx("button_click")


func _make_sell_cb(item_id: String) -> Callable:
	return func():
		GameManager.sell_item(item_id, 1)
		AudioManager.play_sfx("button_click")
