extends Control
class_name InventoryPanel
## Inventar- & Equipment-Panel (umschaltbar).
## Zeigt Inventar-Slots (Grid) und ausgeruestete Items. Tippen benutzt/ausruestet.

@onready var _grid: GridContainer = $Panel/VBox/HBox/InvSide/Scroll/Grid
@onready var _equip_box: VBoxContainer = $Panel/VBox/HBox/EquipSide/EquipList
@onready var _stats_label: RichTextLabel = $Panel/VBox/HBox/EquipSide/StatsLabel
@onready var _close_btn: Button = $Panel/VBox/Header/CloseButton

var _inv: InventorySystem

func _ready() -> void:
	visible = false
	_close_btn.pressed.connect(hide_panel)
	Events.inventory_changed.connect(func(): if visible: _refresh())
	Events.equipment_changed.connect(func(): if visible: _refresh())
	Events.stats_changed.connect(func(_s): if visible: _refresh())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle()

func toggle() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()

func show_panel() -> void:
	_inv = _get_inv()
	visible = true
	_refresh()

func hide_panel() -> void:
	visible = false

func _get_inv() -> InventorySystem:
	if GameManager.player and GameManager.player.has_node("InventorySystem"):
		return GameManager.player.get_node("InventorySystem")
	return null

func _refresh() -> void:
	if _inv == null:
		_inv = _get_inv()
	if _inv == null:
		return
	# --- Inventar-Grid ---
	for c in _grid.get_children():
		c.queue_free()
	for i in _inv.slots.size():
		var slot: Dictionary = _inv.slots[i]
		var item := Database.get_item(slot["id"])
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(84, 84)
		btn.text = "%s\nx%d" % [(item.display_name if item else "?"), slot["amount"]]
		btn.pressed.connect(_inv.use_item.bind(i))
		_grid.add_child(btn)

	# --- Equipment ---
	for c in _equip_box.get_children():
		c.queue_free()
	var slot_names := {
		ItemData.EquipSlot.WEAPON: "Waffe",
		ItemData.EquipSlot.HEAD: "Kopf",
		ItemData.EquipSlot.CHEST: "Brust",
		ItemData.EquipSlot.TRINKET: "Schmuck",
	}
	for slot in slot_names:
		var item_id: StringName = _inv.equipment.get(slot, &"")
		var item := Database.get_item(item_id) if item_id != &"" else null
		var btn := Button.new()
		btn.text = "%s: %s" % [slot_names[slot], (item.display_name if item else "- leer -")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if item:
			btn.pressed.connect(_inv.unequip.bind(slot))
		_equip_box.add_child(btn)

	_refresh_stats()

func _refresh_stats() -> void:
	var char := GameManager.character
	var s: Dictionary = char["stats"]
	_stats_label.text = "[b]%s[/b] - Level %d\n\n" % [char["name"], char["level"]]
	_stats_label.text += "Leben: %d/%d\n" % [char["current_health"], s.get(&"max_health", 0)]
	_stats_label.text += "Mana: %d/%d\n" % [char["current_mana"], s.get(&"max_mana", 0)]
	_stats_label.text += "Staerke: %d\n" % s.get(&"strength", 0)
	_stats_label.text += "Intelligenz: %d\n" % s.get(&"intellect", 0)
	_stats_label.text += "Ausdauer: %d\n" % s.get(&"stamina", 0)
	_stats_label.text += "Ruestung: %d\n" % s.get(&"armor", 0)
	_stats_label.text += "Waffenschaden: %d\n" % s.get(&"weapon_damage", 0)
