extends Node
## Local, fully offline save/load. Everything is written to a single JSON
## file in the user data directory - no network access is used or required.

const SAVE_PATH := "user://save.dat"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"race_id": GameManager.race_id,
		"class_id": GameManager.class_id,
		"level": GameManager.level,
		"xp": GameManager.xp,
		"gold": GameManager.gold,
		"health": GameManager.health,
		"resource": GameManager.resource,
		"inventory": GameManager.inventory,
		"equipped_weapon": GameManager.equipped_weapon,
		"world_position": [
			GameManager.world_position.x,
			GameManager.world_position.y,
			GameManager.world_position.z,
		],
		"quests": QuestManager.serialize(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open save file for writing")
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveManager: save file is corrupt")
		return false
	var data: Dictionary = json.data
	GameManager.race_id = data.get("race_id", "mensch")
	GameManager.class_id = data.get("class_id", "krieger")
	GameManager.level = data.get("level", 1)
	GameManager.xp = data.get("xp", 0)
	GameManager.gold = data.get("gold", 0)
	GameManager._recalc_stats()
	GameManager.health = data.get("health", GameManager.max_health)
	GameManager.resource = data.get("resource", GameManager.max_resource)
	GameManager.inventory = data.get("inventory", {})
	GameManager.equipped_weapon = data.get("equipped_weapon", "")
	var pos: Array = data.get("world_position", [0, 40, 0])
	GameManager.world_position = Vector3(pos[0], pos[1], pos[2])
	GameManager.character_created = true
	QuestManager.deserialize(data.get("quests", {}))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
