extends Node
## Lokales Speichern/Laden via JSON (user://).
## Offline & persistent. Ein Save-Slot (leicht auf mehrere erweiterbar).
##
## Speicherort auf Android: user://  ->  /data/data/<package>/files/
## JSON gewaehlt fuer Lesbarkeit/Debugbarkeit; fuer Verschluesselung siehe Hinweis unten.

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 1

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Sammelt den kompletten Spielzustand und schreibt ihn als JSON.
func save_game() -> bool:
	var player := GameManager.player
	# Aktuelle Position sichern, falls Spieler existiert.
	if player and player is Node3D:
		GameManager.character["spawn_position"] = _v3_to_arr(player.global_position)

	var data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"character": GameManager.character.duplicate(true),
		"quests": QuestTracker.serialize(),
		"inventory": _get_inventory_data(),
	}
	var json := JSON.stringify(data, "\t")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: Konnte Save-Datei nicht oeffnen: %s" % FileAccess.get_open_error())
		return false
	f.store_string(json)
	f.close()
	Events.toast_message.emit("Spiel gespeichert")
	return true

## Laedt den Spielzustand aus JSON. Gibt true bei Erfolg zurueck.
## Achtung: Player/World muessen bereits existieren, bevor Position gesetzt wird.
func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: Ungueltige Save-Datei.")
		return false
	var data: Dictionary = parsed

	# Charakter wiederherstellen (Merge, um neue Felder nicht zu verlieren).
	var saved_char: Dictionary = data.get("character", {})
	for key in saved_char:
		GameManager.character[key] = saved_char[key]
	# JSON macht aus StringName wieder String -> zurueck-konvertieren, sonst
	# schlagen Database-Lookups (per StringName-Key) fehl.
	GameManager.character["class_id"] = StringName(saved_char.get("class_id", "warrior"))
	var skills_sn: Array = []
	for s in saved_char.get("unlocked_skills", []):
		skills_sn.append(StringName(s))
	GameManager.character["unlocked_skills"] = skills_sn
	# JSON-Zahlen sind Floats -> Ganzzahl-Felder zurueckcasten.
	for int_key in ["level", "xp", "gold", "current_health", "current_mana"]:
		GameManager.character[int_key] = int(GameManager.character.get(int_key, 0))
	# spawn_position kommt als Array -> zurueck zu Vector3.
	GameManager.character["spawn_position"] = _arr_to_v3(saved_char.get("spawn_position", [0,1,0]))
	GameManager.is_new_game = false

	QuestTracker.initialize(data.get("quests", {}))
	_pending_inventory = data.get("inventory", {})
	return true

# Inventar wird verzoegert angewandt, sobald InventorySystem bereit ist.
var _pending_inventory: Dictionary = {}

func consume_pending_inventory() -> Dictionary:
	var inv := _pending_inventory
	_pending_inventory = {}
	return inv

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# ---------------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------------
func _get_inventory_data() -> Dictionary:
	var player := GameManager.player
	if player and player.has_node("InventorySystem"):
		return player.get_node("InventorySystem").serialize()
	return {}

func _v3_to_arr(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func _arr_to_v3(a) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(a[0], a[1], a[2])
	if a is Vector3:
		return a
	return Vector3.ZERO

# HINWEIS zur Verschluesselung:
# Fuer Release kann FileAccess.open_encrypted_with_pass() genutzt werden,
# um Save-Manipulation zu erschweren. Fuer einen Prototyp ist Klartext-JSON ok.
