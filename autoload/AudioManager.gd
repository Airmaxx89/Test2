extends Node
## Central audio singleton: short one-shot SFX (button clicks, hits, loot,
## level-up, quest completion) plus looping ambience (forest/campfire). All
## clips are procedurally generated (tools/generate_sounds.py) - no external
## audio assets. Two dedicated AudioServer buses ("SFX", "Music") let the
## pause menu's volume sliders control each independently of Master.

const SFX_PATHS := {
	"button_click": "res://assets/audio/sfx/button_click.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"item_pickup": "res://assets/audio/sfx/item_pickup.wav",
	"level_up": "res://assets/audio/sfx/level_up.wav",
	"quest_complete": "res://assets/audio/sfx/quest_complete.wav",
}
const AMBIENT_PATHS := {
	"forest": "res://assets/audio/ambient/forest_ambient.wav",
	"campfire": "res://assets/audio/ambient/campfire_crackle.wav",
}
const SFX_POOL_SIZE := 6

var _sfx_streams: Dictionary = {}
var _ambient_streams: Dictionary = {}
var _sfx_players: Array = []
var _next_sfx_player: int = 0
var _ambient_player: AudioStreamPlayer
var _current_ambient: String = ""


func _ready() -> void:
	_ensure_bus("SFX")
	_ensure_bus("Music")

	for key in SFX_PATHS.keys():
		var stream: AudioStreamWAV = load(SFX_PATHS[key])
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		_sfx_streams[key] = stream

	for key in AMBIENT_PATHS.keys():
		var stream: AudioStreamWAV = load(AMBIENT_PATHS[key])
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
		_ambient_streams[key] = stream

	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Music"
	add_child(_ambient_player)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var player: AudioStreamPlayer = _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stream = _sfx_streams[sfx_name]
	player.play()


func play_ambient(ambient_name: String) -> void:
	if _current_ambient == ambient_name:
		return
	_current_ambient = ambient_name
	if not _ambient_streams.has(ambient_name):
		_ambient_player.stop()
		return
	_ambient_player.stream = _ambient_streams[ambient_name]
	_ambient_player.play()


func stop_ambient() -> void:
	_current_ambient = ""
	_ambient_player.stop()


func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(clampf(linear, 0.0, 1.0)))


func set_music_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(clampf(linear, 0.0, 1.0)))


func get_sfx_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))


func get_music_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
