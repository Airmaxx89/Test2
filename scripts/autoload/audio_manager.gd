extends Node
## Zentrales Audio-System mit gepoolten AudioStreamPlayer-Nodes.
## Vermeidet staendiges Instanziieren/Freigeben von Playern (GC-schonend, mobil wichtig).
##
## Assets kommen spaeter in assets/audio/. Bis dahin greifen die play_*()-Aufrufe
## ins Leere, ohne Fehler zu werfen (defensive Checks).

const SFX_POOL_SIZE := 12

var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _music_player: AudioStreamPlayer

# Cache fuer geladene Streams: Pfad -> AudioStream
var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# SFX-Pool anlegen.
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
		add_child(p)
		_sfx_players.append(p)
	# Musik-Player.
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	add_child(_music_player)

func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	_cache[path] = s
	return s

## Spielt einen Soundeffekt ueber den naechsten freien Pool-Player (Round-Robin).
func play_sfx(path: String, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _load_stream(path)
	if stream == null:
		return
	var p := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

## Startet Hintergrundmusik (loopt, wenn der Stream loop=true hat).
func play_music(path: String, volume_db := -6.0) -> void:
	var stream := _load_stream(path)
	if stream == null:
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.volume_db = volume_db
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
