extends Node
## Central player-state singleton: race/class, level & XP, health/resource,
## inventory and gold. Pure game-state logic, no rendering.

signal health_changed(current: int, max_value: int)
signal resource_changed(current: float, max_value: float)
signal xp_changed(current: int, needed: int)
signal level_changed(new_level: int)
signal gold_changed(amount: int)
signal inventory_changed()
signal died()

const MAX_LEVEL := 20

var race_id: String = "mensch"
var class_id: String = "krieger"
var level: int = 1
var xp: int = 0
var gold: int = 0

var health: float = 0.0
var max_health: float = 0.0
var resource: float = 0.0
var max_resource: float = 0.0

var inventory: Dictionary = {} # item_id -> count
var equipped_weapon: String = ""

var world_position: Vector3 = Vector3(0, 40, 0)
var character_created: bool = false

var ability_cooldowns: Dictionary = {} # ability_id -> seconds remaining


func xp_required(lvl: int) -> int:
	return 50 * lvl * (lvl + 1)


func setup_character(race: String, cls: String) -> void:
	race_id = race
	class_id = cls
	level = 1
	xp = 0
	gold = 15
	inventory = {}
	ability_cooldowns = {}
	_recalc_stats()
	health = max_health
	var regen: float = ClassData.CLASSES[class_id]["resource_regen"]
	resource = 0.0 if regen <= 0.0 else max_resource
	equipped_weapon = ClassData.CLASSES[class_id]["weapon"]
	add_item(equipped_weapon, 1)
	add_item("health_potion", 2)
	character_created = true
	health_changed.emit(health, max_health)
	resource_changed.emit(resource, max_resource)
	xp_changed.emit(xp, xp_required(level))
	inventory_changed.emit()


func _recalc_stats() -> void:
	var cls_data: Dictionary = ClassData.CLASSES[class_id]
	var race_data: Dictionary = RaceData.RACES[race_id]
	var prev_max_health := max_health
	var prev_max_resource := max_resource
	max_health = float(cls_data["base_health"] + cls_data["health_per_level"] * (level - 1) + race_data["stat_mods"]["health"])
	max_resource = float(cls_data["resource_base"] + race_data["stat_mods"]["mana"])
	if prev_max_health > 0.0:
		health = min(max_health, health + (max_health - prev_max_health))
	if prev_max_resource > 0.0:
		resource = min(max_resource, resource + (max_resource - prev_max_resource))


func get_stat(name: String) -> int:
	var cls_data: Dictionary = ClassData.CLASSES[class_id]
	var race_data: Dictionary = RaceData.RACES[race_id]
	var base := 5 + level
	return base + int(race_data["stat_mods"].get(name, 0))


func add_xp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	xp += amount
	while level < MAX_LEVEL and xp >= xp_required(level):
		xp -= xp_required(level)
		level += 1
		_recalc_stats()
		health = max_health
		resource = max_resource
		level_changed.emit(level)
		health_changed.emit(health, max_health)
		resource_changed.emit(resource, max_resource)
	if level >= MAX_LEVEL:
		xp = 0
	xp_changed.emit(xp, xp_required(min(level, MAX_LEVEL - 1)))


func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)


func spend_resource(amount: float) -> bool:
	if resource < amount:
		return false
	resource -= amount
	resource_changed.emit(resource, max_resource)
	return true


func gain_resource(amount: float) -> void:
	resource = min(max_resource, resource + amount)
	resource_changed.emit(resource, max_resource)


func _process(delta: float) -> void:
	var regen: float = ClassData.CLASSES[class_id]["resource_regen"]
	if regen > 0.0 and resource < max_resource:
		resource = min(max_resource, resource + regen * delta)
		resource_changed.emit(resource, max_resource)
	for id in ability_cooldowns.keys():
		ability_cooldowns[id] = max(0.0, ability_cooldowns[id] - delta)


func is_ability_ready(ability_id: String) -> bool:
	return ability_cooldowns.get(ability_id, 0.0) <= 0.0


func trigger_cooldown(ability_id: String, seconds: float) -> void:
	ability_cooldowns[ability_id] = seconds


func add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count
	inventory_changed.emit()


func remove_item(id: String, count: int = 1) -> bool:
	if inventory.get(id, 0) < count:
		return false
	inventory[id] -= count
	if inventory[id] <= 0:
		inventory.erase(id)
	inventory_changed.emit()
	return true


func item_count(id: String) -> int:
	return inventory.get(id, 0)


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func get_attack_damage() -> int:
	var item: Dictionary = ItemData.get_item(equipped_weapon)
	var base_dmg: int = item.get("damage", 5)
	return base_dmg + int(level * 1.5) + get_stat("strength")


func get_class_abilities() -> Array:
	var out := []
	for ab in ClassData.CLASSES[class_id]["abilities"]:
		if ab["unlock_level"] <= level:
			out.append(ab)
	return out


func reset_for_new_game() -> void:
	race_id = "mensch"
	class_id = "krieger"
	level = 1
	xp = 0
	gold = 0
	health = 0.0
	max_health = 0.0
	resource = 0.0
	max_resource = 0.0
	inventory = {}
	equipped_weapon = ""
	world_position = Vector3(0, 40, 0)
	character_created = false
	ability_cooldowns = {}
