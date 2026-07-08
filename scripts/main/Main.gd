extends Node
class_name Main
## Bootstraps the game: start menu -> (character creation ->) world + UI.
## All content in this project is original; see README.md for the legal
## notice this game ships with.

var world: Node = null
var hud: Node = null
var touch_controls: Node = null
var dialogue_ui: Node = null
var start_menu_ui: Node = null
var char_creation_ui: Node = null
var save_timer: Timer


func _ready() -> void:
	get_tree().root.theme = GameTheme.build_theme()
	_show_start_menu()


func _show_start_menu() -> void:
	start_menu_ui = preload("res://scripts/ui/StartMenuUI.gd").new()
	add_child(start_menu_ui)
	start_menu_ui.new_game_pressed.connect(_on_new_game)
	start_menu_ui.continue_pressed.connect(_on_continue)
	start_menu_ui.set_continue_enabled(SaveManager.has_save())


func _on_new_game() -> void:
	start_menu_ui.queue_free()
	GameManager.reset_for_new_game()
	QuestManager.reset_for_new_game()
	_show_character_creation()


func _show_character_creation() -> void:
	char_creation_ui = preload("res://scripts/ui/CharacterCreationUI.gd").new()
	add_child(char_creation_ui)
	char_creation_ui.character_confirmed.connect(_on_character_confirmed)


func _on_character_confirmed(race_id: String, class_id: String) -> void:
	GameManager.setup_character(race_id, class_id)
	char_creation_ui.queue_free()
	_start_world()


func _on_continue() -> void:
	start_menu_ui.queue_free()
	SaveManager.load_game()
	_start_world()


func _start_world() -> void:
	world = preload("res://scripts/world/World.gd").new()
	add_child(world)

	hud = preload("res://scripts/ui/HUD.gd").new()
	add_child(hud)

	touch_controls = preload("res://scripts/ui/TouchControls.gd").new()
	add_child(touch_controls)

	dialogue_ui = preload("res://scripts/ui/DialogueUI.gd").new()
	add_child(dialogue_ui)

	GameManager.died.connect(_on_player_died)

	save_timer = Timer.new()
	save_timer.wait_time = 20.0
	save_timer.autostart = true
	save_timer.timeout.connect(func(): SaveManager.save_game())
	add_child(save_timer)


func _on_player_died() -> void:
	GameManager.health = GameManager.max_health * 0.5
	GameManager.health_changed.emit(GameManager.health, GameManager.max_health)
	if world and world.player:
		world.player.global_position = Vector3(0, world.get_height(0, 0) + 2, 0)
		world.player.velocity = Vector3.ZERO
	if hud:
		hud.show_message("Du wurdest besiegt und nach Eichenfeld zurückgebracht.", GameTheme.HP_COLOR)


func _notification(what: int) -> void:
	# Android backgrounds/pauses apps far more often than it fully quits
	# them, so save on both to avoid losing progress between sessions.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if GameManager.character_created:
			SaveManager.save_game()
