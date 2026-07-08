extends CanvasLayer
class_name HUD

var health_bar: ProgressBar
var resource_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var gold_label: Label
var zone_label: Label

var quest_log_ui: Node
var inventory_ui: Node


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(260, 110)
	panel.size = Vector2(260, 110)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 16)
	root.add_child(panel)

	level_label = Label.new()
	level_label.position = Vector2(10, 4)
	panel.add_child(level_label)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(230, 18)
	health_bar.position = Vector2(10, 30)
	health_bar.show_percentage = false
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color(0.75, 0.15, 0.15)
	health_bar.add_theme_stylebox_override("fill", hp_style)
	panel.add_child(health_bar)

	resource_bar = ProgressBar.new()
	resource_bar.custom_minimum_size = Vector2(230, 14)
	resource_bar.position = Vector2(10, 54)
	resource_bar.show_percentage = false
	var res_style := StyleBoxFlat.new()
	res_style.bg_color = Color(0.2, 0.4, 0.8)
	resource_bar.add_theme_stylebox_override("fill", res_style)
	panel.add_child(resource_bar)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(230, 10)
	xp_bar.position = Vector2(10, 74)
	xp_bar.show_percentage = false
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = Color(0.8, 0.7, 0.2)
	xp_bar.add_theme_stylebox_override("fill", xp_style)
	panel.add_child(xp_bar)

	gold_label = Label.new()
	gold_label.position = Vector2(10, 90)
	panel.add_child(gold_label)

	zone_label = Label.new()
	zone_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	zone_label.position = Vector2(0, 16)
	zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_label.add_theme_font_size_override("font_size", 22)
	root.add_child(zone_label)

	var quest_btn := Button.new()
	quest_btn.text = "Quests"
	quest_btn.custom_minimum_size = Vector2(90, 50)
	quest_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_btn.position = Vector2(-200, 16)
	root.add_child(quest_btn)

	var inv_btn := Button.new()
	inv_btn.text = "Inventar"
	inv_btn.custom_minimum_size = Vector2(90, 50)
	inv_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inv_btn.position = Vector2(-100, 16)
	root.add_child(inv_btn)

	quest_log_ui = preload("res://scripts/ui/QuestLogUI.gd").new()
	add_child(quest_log_ui)
	quest_btn.pressed.connect(func(): quest_log_ui.toggle())

	inventory_ui = preload("res://scripts/ui/InventoryUI.gd").new()
	add_child(inventory_ui)
	inv_btn.pressed.connect(func(): inventory_ui.toggle())

	GameManager.health_changed.connect(_on_health_changed)
	GameManager.resource_changed.connect(_on_resource_changed)
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.gold_changed.connect(_on_gold_changed)

	_on_health_changed(GameManager.health, GameManager.max_health)
	_on_resource_changed(GameManager.resource, GameManager.max_resource)
	_on_xp_changed(GameManager.xp, GameManager.xp_required(GameManager.level))
	_on_gold_changed(GameManager.gold)
	level_label.text = "Level %d" % GameManager.level


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var zone_id: String = ZoneData.get_zone(int(player.global_position.x))
		zone_label.text = ZoneData.ZONES[zone_id]["name"]


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


func _on_resource_changed(current: float, max_value: float) -> void:
	resource_bar.max_value = max_value
	resource_bar.value = current


func _on_xp_changed(current: int, needed: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current


func _on_level_changed(new_level: int) -> void:
	level_label.text = "Level %d" % new_level


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "%d Kupfermünzen" % amount
