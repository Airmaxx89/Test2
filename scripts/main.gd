extends Node
class_name Main
## Einstiegspunkt & Fluss-Steuerung: Menue -> Charaktererstellung -> Welt (+ HUD).
## Haelt die aktuell geladene Welt und die UI-Layer. Verwaltet Pause & Speichern.

@export var world_scene: PackedScene
@export var hud_scene: PackedScene

@onready var _menu_layer: CanvasLayer = $MenuLayer
@onready var _main_menu: MainMenu = $MenuLayer/MainMenu
@onready var _char_creation: CharacterCreation = $MenuLayer/CharacterCreation
@onready var _ui_layer: Node = $UILayer

var _world: Node = null
var _hud: HUD = null
var _autosave_accum := 0.0

func _ready() -> void:
	if world_scene == null:
		world_scene = load("res://scenes/world/world.tscn")
	if hud_scene == null:
		hud_scene = load("res://scenes/ui/ui_hud.tscn")
	_main_menu.new_game_requested.connect(_on_new_game)
	_main_menu.continue_requested.connect(_on_continue)
	_char_creation.created.connect(_on_character_created)
	_char_creation.cancelled.connect(_show_main_menu)
	_show_main_menu()

func _show_main_menu() -> void:
	_menu_layer.visible = true
	_main_menu.visible = true
	_char_creation.visible = false

func _on_new_game() -> void:
	_main_menu.visible = false
	_char_creation.visible = true

func _on_continue() -> void:
	if SaveManager.load_game():
		_start_world(false)
	else:
		Events.toast_message.emit("Kein Spielstand gefunden")

func _on_character_created(char_name: String, class_id: StringName) -> void:
	GameManager.new_game(char_name, class_id)
	QuestTracker.initialize()
	_start_world(true)

## Baut Welt + HUD auf und blendet das Menue aus.
func _start_world(is_new: bool) -> void:
	_menu_layer.visible = false
	# Bestehende Welt entfernen (Neustart).
	if _world:
		_world.queue_free()
		_world = null
	# HUD ZUERST erstellen, damit es das player_ready-Signal der Welt empfaengt.
	if _hud == null:
		_hud = hud_scene.instantiate()
		_ui_layer.add_child(_hud)
	# Dann die Welt (spawnt Spieler + Kamera und emittiert player_ready).
	_world = world_scene.instantiate()
	add_child(_world)
	Events.game_started.emit()
	if is_new:
		# Startausruestung geben.
		_grant_starter_kit(GameManager.character["class_id"])

func _grant_starter_kit(class_id: StringName) -> void:
	# Nach kurzer Verzoegerung, damit InventorySystem bereit ist.
	await get_tree().process_frame
	await get_tree().process_frame
	Events.item_added.emit(&"potion_health", 3)
	if class_id == &"warrior":
		Events.item_added.emit(&"iron_sword", 1)
	else:
		Events.item_added.emit(&"apprentice_staff", 1)
	# Erste Waffe direkt anlegen.
	if GameManager.player and GameManager.player.has_node("InventorySystem"):
		var inv = GameManager.player.get_node("InventorySystem")
		inv.equip_item(&"iron_sword" if class_id == &"warrior" else &"apprentice_staff")

func _process(delta: float) -> void:
	# Auto-Save alle 60 Sekunden (nur im laufenden Spiel).
	if _world and not get_tree().paused:
		_autosave_accum += delta
		if _autosave_accum >= 60.0:
			_autosave_accum = 0.0
			SaveManager.save_game()

func _notification(what: int) -> void:
	# Beim Verlassen (App in Hintergrund / schliessen) speichern -> mobil wichtig.
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _world:
			SaveManager.save_game()
