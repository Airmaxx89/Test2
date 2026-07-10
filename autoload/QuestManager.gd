extends Node
## Tracks active/completed quests and objective progress. Reads quest
## definitions from the static QuestData database.

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

# quest_id -> {"kill_counts": {mob_id:int}, "reached": {location_id:bool}}
var active_quests: Dictionary = {}
var completed_quests: Array = []


func _ready() -> void:
	# Collect-objectives read live inventory counts, so the quest log needs
	# to refresh whenever the inventory changes (picked up, sold, used, ...).
	GameManager.inventory_changed.connect(notify_inventory_change)


func is_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)


func is_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)


func is_quest_offered(quest_id: String) -> bool:
	if is_active(quest_id) or is_completed(quest_id):
		return false
	var q: Dictionary = QuestData.get_quest(quest_id)
	if q.is_empty():
		return false
	return q["requires"] == "" or completed_quests.has(q["requires"])


func get_available_quests_for_npc(npc_id: String) -> Array:
	var out := []
	for quest_id in QuestData.QUESTS.keys():
		var q: Dictionary = QuestData.QUESTS[quest_id]
		if q["giver"] == npc_id and is_quest_offered(quest_id):
			out.append(quest_id)
	return out


func get_turn_in_quests_for_npc(npc_id: String) -> Array:
	var out := []
	for quest_id in active_quests.keys():
		var q: Dictionary = QuestData.get_quest(quest_id)
		if q["turn_in"] == npc_id and is_quest_complete(quest_id):
			out.append(quest_id)
	return out


func start_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		return
	active_quests[quest_id] = {"kill_counts": {}, "reached": {}}
	quest_started.emit(quest_id)


func get_objective_progress(quest_id: String, obj_index: int) -> int:
	if not active_quests.has(quest_id):
		return 0
	var q: Dictionary = QuestData.get_quest(quest_id)
	var obj: Dictionary = q["objectives"][obj_index]
	var state: Dictionary = active_quests[quest_id]
	match obj["type"]:
		"kill":
			return state["kill_counts"].get(obj["target"], 0)
		"collect":
			return min(GameManager.item_count(obj["target"]), obj["count"])
		"reach":
			return 1 if state["reached"].get(obj["target"], false) else 0
		_:
			return 0


func is_quest_complete(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	var q: Dictionary = QuestData.get_quest(quest_id)
	for i in q["objectives"].size():
		var obj: Dictionary = q["objectives"][i]
		if get_objective_progress(quest_id, i) < obj["count"]:
			return false
	return true


func notify_kill(mob_id: String) -> void:
	for quest_id in active_quests.keys():
		var q: Dictionary = QuestData.get_quest(quest_id)
		var changed := false
		for obj in q["objectives"]:
			if obj["type"] == "kill" and obj["target"] == mob_id:
				var counts: Dictionary = active_quests[quest_id]["kill_counts"]
				counts[mob_id] = min(obj["count"], counts.get(mob_id, 0) + 1)
				changed = true
		if changed:
			quest_updated.emit(quest_id)


func notify_reach(location_id: String) -> void:
	for quest_id in active_quests.keys():
		var q: Dictionary = QuestData.get_quest(quest_id)
		var changed := false
		for obj in q["objectives"]:
			if obj["type"] == "reach" and obj["target"] == location_id:
				active_quests[quest_id]["reached"][location_id] = true
				changed = true
		if changed:
			quest_updated.emit(quest_id)


func notify_inventory_change() -> void:
	# Collect-objectives read live inventory counts; just re-broadcast so the
	# quest log UI refreshes.
	for quest_id in active_quests.keys():
		quest_updated.emit(quest_id)


func complete_quest(quest_id: String) -> bool:
	if not is_quest_complete(quest_id):
		return false
	var q: Dictionary = QuestData.get_quest(quest_id)
	for obj in q["objectives"]:
		if obj["type"] == "collect":
			GameManager.remove_item(obj["target"], obj["count"])
	GameManager.add_xp(q["xp_reward"])
	GameManager.add_gold(q["coin_reward"])
	for item_id in q["item_rewards"].keys():
		GameManager.add_item(item_id, q["item_rewards"][item_id])
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	AudioManager.play_sfx("quest_complete")
	quest_completed.emit(quest_id)
	return true


func serialize() -> Dictionary:
	return {"active_quests": active_quests, "completed_quests": completed_quests}


func deserialize(data: Dictionary) -> void:
	active_quests = data.get("active_quests", {})
	completed_quests = data.get("completed_quests", [])


func reset_for_new_game() -> void:
	active_quests = {}
	completed_quests = []
