extends Node
## Zentraler Spielzustand-Halter (Autoload Singleton).
## Haelt Charakterdaten, Fortschritt und globale Performance-Settings.
## Bewusst schlank: Gameplay-Logik liegt in den jeweiligen Systemen.

const MAX_LEVEL := 20
const TARGET_FPS := 60

## Laufender Charakter-Zustand (wird gespeichert/geladen).
var character := {
	"name": "Held",
	"class_id": &"warrior",
	"level": 1,
	"xp": 0,
	"gold": 0,
	"current_health": 100,
	"current_mana": 50,
	# abgeleitete Stats werden von LevelingSystem berechnet
	"stats": {},
	"unlocked_skills": [] as Array,
	"spawn_position": Vector3.ZERO,
}

var is_new_game := true
var player: Node = null            # gesetzt vom PlayerController via player_ready

func _ready() -> void:
	# FPS-Cap fuer Batterieschonung & konstante Frametimes.
	Engine.max_fps = TARGET_FPS
	# Bei laengerer Inaktivitaet weiter rendern (Gameplay), aber sauber pausierbar.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()
	Events.player_ready.connect(_on_player_ready)

## Legt die Input-Actions per Code an (robust: kein fragiler [input]-Block in
## project.godot). Tastatur dient nur dem Desktop-Test; mobil laeuft alles ueber
## Touch. Fehlt eine Action, wird sie mit ihrer Standard-Taste erzeugt.
func _setup_input_map() -> void:
	var actions := {
		"move_forward": KEY_W,
		"move_back": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"interact": KEY_E,
		"sprint": KEY_SHIFT,
		"toggle_journal": KEY_J,
		"toggle_inventory": KEY_I,
	}
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)
			var ev := InputEventKey.new()
			ev.physical_keycode = actions[action_name]
			InputMap.action_add_event(action_name, ev)

func _on_player_ready(p: Node) -> void:
	player = p

## Startet ein neues Spiel mit Charakter-Erstellungs-Daten.
func new_game(char_name: String, class_id: StringName) -> void:
	is_new_game = true
	character = {
		"name": char_name,
		"class_id": class_id,
		"level": 1,
		"xp": 0,
		"gold": 0,
		"current_health": 100,
		"current_mana": 50,
		"stats": {},
		"unlocked_skills": [],
		"spawn_position": Vector3.ZERO,
	}
	# Starter-Skills der Klasse freischalten.
	var cls: ClassData = Database.get_char_class(class_id)
	if cls:
		for sid in cls.starter_skill_ids:
			if sid not in character["unlocked_skills"]:
				character["unlocked_skills"].append(sid)

func get_class_data() -> ClassData:
	return Database.get_char_class(character["class_id"])

func set_pause(paused: bool) -> void:
	get_tree().paused = paused
	Events.game_paused.emit(paused)
