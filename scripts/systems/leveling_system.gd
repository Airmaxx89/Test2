extends Node
class_name LevelingSystem
## Verwaltet XP, Level-Ups (bis MAX_LEVEL=20), Stat-Neuberechnung und
## Skill-Freischaltung. Als Kind-Node am Player; liest/schreibt GameManager.character.

signal recalculated(stats: Dictionary)

func _ready() -> void:
	Events.xp_gained.connect(add_xp)
	# Stats einmalig beim Start berechnen (fuer neues Spiel wichtig).
	recalculate_stats(true)

## Benoetigte Gesamt-XP fuer ein bestimmtes Level (klassische RPG-Kurve).
static func xp_to_reach(level: int) -> int:
	# Level 1 = 0 XP; danach quadratisch ansteigend.
	if level <= 1:
		return 0
	return int(round(50.0 * pow(level - 1, 2) + 50.0 * (level - 1)))

## XP fuer den Sprung von level -> level+1.
static func xp_for_next(level: int) -> int:
	return xp_to_reach(level + 1) - xp_to_reach(level)

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	var char := GameManager.character
	if char["level"] >= GameManager.MAX_LEVEL:
		return
	char["xp"] += amount
	# Mehrere Level-Ups in einem Schritt moeglich.
	while char["level"] < GameManager.MAX_LEVEL and char["xp"] >= xp_to_reach(char["level"] + 1):
		_level_up()

func _level_up() -> void:
	var char := GameManager.character
	char["level"] += 1
	recalculate_stats(true)   # Full-Heal bei Level-Up (WoW-Feeling)
	_unlock_skills_for_level(char["level"])
	Events.level_up.emit(char["level"])
	Events.toast_message.emit("Level %d erreicht!" % char["level"])
	AudioManager.play_sfx("res://assets/audio/sfx_levelup.ogg")

func _unlock_skills_for_level(level: int) -> void:
	var cls := GameManager.get_class_data()
	if cls == null:
		return
	if cls.skill_unlocks.has(level):
		var sid: StringName = cls.skill_unlocks[level]
		if sid not in GameManager.character["unlocked_skills"]:
			GameManager.character["unlocked_skills"].append(sid)
			Events.skill_unlocked.emit(sid)
			var sk := Database.get_skill(sid)
			if sk:
				Events.toast_message.emit("Neuer Skill: %s" % sk.display_name)

## Berechnet abgeleitete Stats aus Klasse + Level + Equipment.
func recalculate_stats(full_heal := false) -> void:
	var char := GameManager.character
	var cls := GameManager.get_class_data()
	if cls == null:
		return
	var stats := cls.stats_at_level(char["level"])
	# Equipment-Boni addieren.
	var equip_bonus := _get_equipment_bonus()
	stats[&"strength"] += equip_bonus.get(&"strength", 0)
	stats[&"intellect"] += equip_bonus.get(&"intellect", 0)
	stats[&"stamina"] += equip_bonus.get(&"stamina", 0)
	stats[&"armor"] = equip_bonus.get(&"armor", 0)
	# Stamina beeinflusst maximale HP (10 HP je Stamina-Punkt ueber Basis).
	stats[&"max_health"] += stats[&"stamina"] * 5
	stats[&"weapon_damage"] = equip_bonus.get(&"weapon_damage", 0)

	char["stats"] = stats
	# HP/Mana clampen bzw. bei Bedarf voll auffuellen.
	if full_heal:
		char["current_health"] = stats[&"max_health"]
		char["current_mana"] = stats[&"max_mana"]
	else:
		char["current_health"] = mini(char["current_health"], stats[&"max_health"])
		char["current_mana"] = mini(char["current_mana"], stats[&"max_mana"])

	Events.stats_changed.emit(stats)
	Events.player_healed.emit(0, char["current_health"], stats[&"max_health"])
	Events.player_mana_changed.emit(char["current_mana"], stats[&"max_mana"])
	recalculated.emit(stats)

func _get_equipment_bonus() -> Dictionary:
	var bonus := {&"strength":0, &"intellect":0, &"stamina":0, &"armor":0, &"weapon_damage":0}
	var player := GameManager.player
	if player == null or not player.has_node("InventorySystem"):
		return bonus
	var inv = player.get_node("InventorySystem")
	for slot in inv.equipment:
		var item_id: StringName = inv.equipment[slot]
		if item_id == &"":
			continue
		var item := Database.get_item(item_id)
		if item == null:
			continue
		bonus[&"strength"] += item.bonus_strength
		bonus[&"intellect"] += item.bonus_intellect
		bonus[&"stamina"] += item.bonus_stamina
		bonus[&"armor"] += item.bonus_armor
		bonus[&"weapon_damage"] += item.weapon_damage
	return bonus
