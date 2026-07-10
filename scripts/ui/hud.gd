extends CanvasLayer
class_name HUD
## Haupt-HUD (CanvasLayer, damit es unabhaengig von der 3D-Kamera skaliert).
## Bindet Touch-Controls an den Spieler, zeigt Vitalwerte, Skill-Hotbar,
## Quest-Tracker, Toasts und Floating Damage Numbers.
##
## Node-Referenzen kommen aus ui_hud.tscn.

@export var damage_number_scene: PackedScene

# --- Node-Referenzen (Pfade laut ui_hud.tscn) ---
@onready var _joystick: VirtualJoystick = $Controls/VirtualJoystick
@onready var _btn_jump: TouchButton = $Controls/ActionButtons/JumpButton
@onready var _btn_sprint: TouchButton = $Controls/ActionButtons/SprintButton
@onready var _btn_interact: TouchButton = $Controls/ActionButtons/InteractButton
@onready var _skill_bar: HBoxContainer = $Controls/SkillBar
@onready var _hp_bar: ProgressBar = $TopLeft/VitalsPanel/HealthBar
@onready var _mp_bar: ProgressBar = $TopLeft/VitalsPanel/ManaBar
@onready var _xp_bar: ProgressBar = $TopLeft/VitalsPanel/XPBar
@onready var _level_label: Label = $TopLeft/VitalsPanel/LevelLabel
@onready var _name_label: Label = $TopLeft/VitalsPanel/NameLabel
@onready var _gold_label: Label = $TopRight/GoldLabel
@onready var _quest_tracker_box: VBoxContainer = $QuestTracker/QuestList
@onready var _toast_label: Label = $ToastLabel
@onready var _interact_prompt: Label = $InteractPrompt
@onready var _damage_layer: Control = $DamageNumbers

# Panels (im HUD enthalten) + Menue-Buttons.
@onready var _journal: QuestJournal = get_node_or_null("QuestJournal")
@onready var _inventory: InventoryPanel = get_node_or_null("InventoryPanel")
@onready var _btn_journal: Button = get_node_or_null("TopRight/MenuButtons/JournalButton")
@onready var _btn_inventory: Button = get_node_or_null("TopRight/MenuButtons/InventoryButton")
@onready var _btn_save: Button = get_node_or_null("TopRight/MenuButtons/SaveButton")

var _player: PlayerController
var _combat: CombatSystem
var _skill_buttons: Array[TouchButton] = []
var _toast_tween: Tween

func _ready() -> void:
	# Touch-Controls verbinden.
	_joystick.moved.connect(_on_joystick_moved)
	_btn_jump.activated.connect(func(_id): if _player: _player.do_jump())
	_btn_interact.activated.connect(func(_id): if _player: _player.try_interact())
	# Sprint: gedrueckt-halten. TouchButton feuert bei down; wir toggeln per button_up.
	_btn_sprint.button_down.connect(func(): if _player: _player.set_sprint(true))
	_btn_sprint.button_up.connect(func(): if _player: _player.set_sprint(false))

	# Skill-Buttons einsammeln und verbinden.
	for child in _skill_bar.get_children():
		if child is TouchButton:
			_skill_buttons.append(child)
			child.activated.connect(_on_skill_pressed)

	# Event-Bus abonnieren.
	Events.player_ready.connect(_on_player_ready)
	Events.player_damaged.connect(func(_a, hp, max_hp): _set_hp(hp, max_hp))
	Events.player_healed.connect(func(_a, hp, max_hp): _set_hp(hp, max_hp))
	Events.player_mana_changed.connect(_set_mp)
	Events.stats_changed.connect(func(_s): _refresh_vitals())
	Events.xp_gained.connect(func(_a): _refresh_xp())
	Events.level_up.connect(func(_l): _refresh_all())
	Events.gold_changed.connect(_set_gold)
	Events.skill_unlocked.connect(func(_id): _refresh_skill_bar())
	Events.equipment_changed.connect(func(): _refresh_skill_bar())
	Events.toast_message.connect(_show_toast)
	Events.damage_number.connect(_spawn_damage_number)
	Events.interactable_in_range.connect(_on_interactable_in_range)
	Events.interactable_out_of_range.connect(func(_n): _interact_prompt.visible = false)
	Events.quest_accepted.connect(func(_q): _refresh_quest_tracker())
	Events.quest_objective_updated.connect(func(_a,_b,_c,_d): _refresh_quest_tracker())
	Events.quest_ready_to_turnin.connect(func(_id): _refresh_quest_tracker())
	Events.quest_completed.connect(func(_q): _refresh_quest_tracker())

	# Menue-Buttons (Mobile) mit Panels verbinden.
	if _btn_journal and _journal:
		_btn_journal.pressed.connect(_journal.toggle)
	if _btn_inventory and _inventory:
		_btn_inventory.pressed.connect(_inventory.toggle)
	if _btn_save:
		_btn_save.pressed.connect(func(): SaveManager.save_game())

	_interact_prompt.visible = false
	_toast_label.modulate.a = 0.0

	# Fallback: Falls der Spieler bereits existiert (player_ready wurde vor
	# unserem _ready emittiert), direkt anbinden.
	if GameManager.player:
		_on_player_ready(GameManager.player)

func _on_player_ready(p: Node) -> void:
	_player = p
	_combat = p.get_node("CombatSystem")
	_refresh_all()

func _process(_delta: float) -> void:
	# Skill-Cooldown-Overlays aktualisieren.
	if _combat:
		for i in _skill_buttons.size():
			_skill_buttons[i].set_cooldown(_combat.get_cooldown_ratio(i))

# ---------------------------------------------------------------------------
#  Input
# ---------------------------------------------------------------------------
func _on_joystick_moved(vec: Vector2) -> void:
	if _player:
		_player.set_move_input(vec)

func _on_skill_pressed(button_id: StringName) -> void:
	if _combat == null:
		return
	var slot := int(String(button_id).replace("skill_", ""))
	_combat.use_skill(slot)

# ---------------------------------------------------------------------------
#  Vitals / Progression
# ---------------------------------------------------------------------------
func _refresh_all() -> void:
	_refresh_vitals()
	_refresh_xp()
	_refresh_skill_bar()
	_refresh_quest_tracker()
	_name_label.text = GameManager.character["name"]
	_set_gold(GameManager.character["gold"])

func _refresh_vitals() -> void:
	var char := GameManager.character
	var stats: Dictionary = char["stats"]
	_set_hp(char["current_health"], stats.get(&"max_health", 1))
	_set_mp(char["current_mana"], stats.get(&"max_mana", 1))
	_level_label.text = "Lv %d" % char["level"]

func _set_hp(hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp

func _set_mp(mp: int, max_mp: int) -> void:
	_mp_bar.max_value = max_mp
	_mp_bar.value = mp

func _refresh_xp() -> void:
	var char := GameManager.character
	var lvl: int = char["level"]
	if lvl >= GameManager.MAX_LEVEL:
		_xp_bar.max_value = 1; _xp_bar.value = 1
		return
	var cur_base := LevelingSystem.xp_to_reach(lvl)
	var next_base := LevelingSystem.xp_to_reach(lvl + 1)
	_xp_bar.max_value = next_base - cur_base
	_xp_bar.value = char["xp"] - cur_base

func _set_gold(amount: int) -> void:
	_gold_label.text = "%d Gold" % amount

# ---------------------------------------------------------------------------
#  Skill-Hotbar
# ---------------------------------------------------------------------------
func _refresh_skill_bar() -> void:
	if _combat == null:
		return
	var hotbar: Array = _combat.get_hotbar()
	for i in _skill_buttons.size():
		var btn := _skill_buttons[i]
		if i < hotbar.size():
			var sk := Database.get_skill(hotbar[i])
			btn.visible = true
			btn.set_label(sk.display_name.substr(0, 3) if sk else "")
			btn.set_icon_texture(sk.icon if sk else null)
			btn.tooltip_text = sk.display_name if sk else ""
		else:
			btn.visible = false

# ---------------------------------------------------------------------------
#  Quest-Tracker
# ---------------------------------------------------------------------------
func _refresh_quest_tracker() -> void:
	for c in _quest_tracker_box.get_children():
		c.queue_free()
	for qid in QuestTracker.active_quests():
		var q := Database.get_quest(qid)
		if q == null:
			continue
		var title := Label.new()
		title.text = q.title
		title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		title.add_theme_font_size_override("font_size", 18)
		_quest_tracker_box.add_child(title)
		var progress := QuestTracker.get_progress(qid)
		for i in q.objectives.size():
			var obj: Dictionary = q.objectives[i]
			var line := Label.new()
			var done: int = progress[i] if i < progress.size() else 0
			var total: int = int(obj["amount"])
			line.text = "  - %s: %d/%d" % [obj["label"], done, total]
			line.add_theme_font_size_override("font_size", 15)
			if done >= total:
				line.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
			_quest_tracker_box.add_child(line)

# ---------------------------------------------------------------------------
#  Toast / Interact-Prompt / Damage Numbers
# ---------------------------------------------------------------------------
func _show_toast(text: String) -> void:
	_toast_label.text = text
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast_label, "modulate:a", 0.0, 0.6)

func _on_interactable_in_range(node: Node) -> void:
	_interact_prompt.visible = true
	var nm := "Interagieren"
	if node.get("display_name") != null and node.display_name != "":
		nm = node.display_name
	_interact_prompt.text = "[E] / Tippen: %s" % nm

func _spawn_damage_number(world_pos: Vector3, amount: int, is_crit: bool, to_player: bool) -> void:
	if damage_number_scene == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if cam.is_position_behind(world_pos):
		return
	var screen := cam.unproject_position(world_pos)
	var dn := damage_number_scene.instantiate()
	_damage_layer.add_child(dn)
	dn.position = screen
	if dn.has_method("show_number"):
		dn.show_number(amount, is_crit, to_player)
