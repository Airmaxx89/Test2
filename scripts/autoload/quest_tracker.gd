extends Node
## Laufzeit-Verwaltung aller Quest-Zustaende (Autoload).
## Haelt: verfuegbare, aktive und abgeschlossene Quests + Fortschritt pro Ziel.
## Reagiert auf Gameplay-Events (Kills, Item-Pickups) und aktualisiert Ziele.

enum State { AVAILABLE, ACTIVE, READY_TO_TURNIN, COMPLETED }

# quest_id -> { "state": State, "progress": Array[int] (pro Objective) }
var quest_states: Dictionary = {}

func _ready() -> void:
	Events.enemy_killed.connect(_on_enemy_killed)
	# COLLECT-Ziele werden aus dem tatsaechlichen Inventarbestand abgeleitet.
	# inventory_changed feuert NACH dem Hinzufuegen -> kein Timing-Problem
	# (im Gegensatz zu item_added, das vor dem Inventar-Update laufen koennte).
	Events.inventory_changed.connect(_on_inventory_changed)

## Beim Spielstart / Laden: Zustaende initialisieren.
func initialize(saved: Dictionary = {}) -> void:
	quest_states.clear()
	if saved.is_empty():
		# Erste Quest der Kette verfuegbar machen.
		_set_available(&"q_welcome")
	else:
		for qid in saved:
			var s: Dictionary = saved[qid]
			# JSON-Zahlen sind Floats -> Fortschritt zu int casten.
			var prog: Array = []
			for p in (s.get("progress", []) as Array):
				prog.append(int(p))
			quest_states[StringName(qid)] = {
				"state": int(s.get("state", State.AVAILABLE)),
				"progress": prog,
			}

func _set_available(qid: StringName) -> void:
	var q := Database.get_quest(qid)
	if q == null:
		return
	if not quest_states.has(qid):
		quest_states[qid] = {"state": State.AVAILABLE, "progress": []}

func is_available(qid: StringName) -> bool:
	return quest_states.get(qid, {}).get("state", -1) == State.AVAILABLE

func is_active(qid: StringName) -> bool:
	return quest_states.get(qid, {}).get("state", -1) == State.ACTIVE

func is_completed(qid: StringName) -> bool:
	return quest_states.get(qid, {}).get("state", -1) == State.COMPLETED

func get_state(qid: StringName) -> int:
	return quest_states.get(qid, {}).get("state", -1)

func get_progress(qid: StringName) -> Array:
	return quest_states.get(qid, {}).get("progress", [])

func active_quests() -> Array:
	var result: Array = []
	for qid in quest_states:
		var st: int = quest_states[qid]["state"]
		if st == State.ACTIVE or st == State.READY_TO_TURNIN:
			result.append(qid)
	return result

## NPC bietet Quest an -> Spieler akzeptiert.
func accept_quest(qid: StringName) -> void:
	var q := Database.get_quest(qid)
	if q == null or not is_available(qid):
		return
	if GameManager.character["level"] < q.required_level:
		Events.toast_message.emit("Benoetigt Level %d" % q.required_level)
		return
	var progress: Array = []
	progress.resize(q.objective_count())
	progress.fill(0)
	quest_states[qid] = {"state": State.ACTIVE, "progress": progress}
	Events.quest_accepted.emit(q)
	Events.toast_message.emit("Quest angenommen: %s" % q.title)
	_check_ready(qid)

## Quest beim NPC abgeben -> Belohnungen vergeben, naechste Quest freischalten.
func turn_in_quest(qid: StringName) -> bool:
	var q := Database.get_quest(qid)
	if q == null or get_state(qid) != State.READY_TO_TURNIN:
		return false
	quest_states[qid]["state"] = State.COMPLETED
	# Belohnungen
	GameManager.character["gold"] += q.reward_gold
	Events.gold_changed.emit(GameManager.character["gold"])
	for entry in q.reward_items:
		Events.item_added.emit(StringName(entry["id"]), int(entry["amount"]))
	# Quest-Collect-Items aus Inventar entfernen (verbraucht).
	for obj in q.objectives:
		if obj["type"] == QuestData.ObjectiveType.COLLECT:
			Events.item_removed.emit(StringName(obj["target"]), int(obj["amount"]))
	Events.xp_gained.emit(q.reward_xp)
	Events.quest_completed.emit(q)
	Events.toast_message.emit("Quest abgeschlossen: %s (+%d XP)" % [q.title, q.reward_xp])
	# Naechste Quest der Kette freischalten.
	if q.next_quest_id != &"":
		_set_available(q.next_quest_id)
	return true

## Wird von NPCs/Trigger aufgerufen (TALK-, ESCORT-, REACH-Ziele).
func report_objective(qid: StringName, type: int, target: StringName, amount := 1) -> void:
	if not is_active(qid):
		return
	_apply_progress(qid, type, target, amount)

func _on_enemy_killed(enemy_data: EnemyData, _pos: Vector3) -> void:
	if enemy_data == null:
		return
	for qid in active_quests():
		_apply_progress(qid, QuestData.ObjectiveType.KILL, enemy_data.quest_tag, 1)

## Nach jeder Inventar-Aenderung: alle COLLECT-Ziele aktiver Quests aus dem
## realen Bestand neu berechnen (robust gegen Aufsammeln UND Verlieren).
func _on_inventory_changed() -> void:
	for qid in active_quests():
		var q := Database.get_quest(qid)
		if q == null:
			continue
		for i in q.objectives.size():
			var obj: Dictionary = q.objectives[i]
			if obj["type"] == QuestData.ObjectiveType.COLLECT:
				_apply_progress(qid, QuestData.ObjectiveType.COLLECT, StringName(obj["target"]), 0, true)

## Kernlogik: passenden Ziel-Index finden und Fortschritt erhoehen.
func _apply_progress(qid: StringName, type: int, target: StringName, amount: int, is_absolute := false) -> void:
	var q := Database.get_quest(qid)
	if q == null:
		return
	var progress: Array = quest_states[qid]["progress"]
	var changed := false
	for i in q.objectives.size():
		var obj: Dictionary = q.objectives[i]
		if obj["type"] == type and StringName(obj["target"]) == target:
			var total: int = int(obj["amount"])
			if is_absolute:
				# Fuer COLLECT: aktueller Inventarbestand ist maßgeblich.
				progress[i] = mini(_inventory_count(target), total)
			else:
				progress[i] = mini(progress[i] + amount, total)
			Events.quest_objective_updated.emit(qid, i, progress[i], total)
			changed = true
	if changed:
		_check_ready(qid)

func _inventory_count(item_id: StringName) -> int:
	if GameManager.player and GameManager.player.has_node("InventorySystem"):
		return GameManager.player.get_node("InventorySystem").count_item(item_id)
	return 0

func _check_ready(qid: StringName) -> void:
	var q := Database.get_quest(qid)
	var progress: Array = quest_states[qid]["progress"]
	for i in q.objectives.size():
		if progress[i] < int(q.objectives[i]["amount"]):
			return
	if quest_states[qid]["state"] == State.ACTIVE:
		quest_states[qid]["state"] = State.READY_TO_TURNIN
		Events.quest_ready_to_turnin.emit(qid)
		Events.toast_message.emit("Quest bereit zur Abgabe!")

## Fuer SaveManager.
func serialize() -> Dictionary:
	var out: Dictionary = {}
	for qid in quest_states:
		out[String(qid)] = {
			"state": quest_states[qid]["state"],
			"progress": quest_states[qid]["progress"],
		}
	return out
