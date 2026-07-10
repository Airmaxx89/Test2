extends Node
class_name InventorySystem
## Inventar + Equipment (als Kind-Node am Player).
## Inventar = Array von Stacks: { "id": StringName, "amount": int }
## Equipment = Dictionary EquipSlot -> StringName(item_id)

const MAX_SLOTS := 24

var slots: Array[Dictionary] = []          # Inventar-Stacks
var equipment: Dictionary = {              # Ausgeruestete Items je Slot
	ItemData.EquipSlot.WEAPON: &"",
	ItemData.EquipSlot.HEAD: &"",
	ItemData.EquipSlot.CHEST: &"",
	ItemData.EquipSlot.TRINKET: &"",
}

func _ready() -> void:
	Events.item_added.connect(add_item)
	Events.item_removed.connect(remove_item)
	# Verzoegertes Laden aus Save.
	call_deferred("_apply_pending_save")

func _apply_pending_save() -> void:
	var data := SaveManager.consume_pending_inventory()
	if data.is_empty():
		return
	slots.clear()
	for s in data.get("slots", []):
		slots.append({"id": StringName(s["id"]), "amount": int(s["amount"])})
	for slot_key in data.get("equipment", {}):
		equipment[int(slot_key)] = StringName(data["equipment"][slot_key])
	Events.inventory_changed.emit()
	Events.equipment_changed.emit()
	# Stats mit geladenem Equipment neu berechnen.
	if get_parent().has_node("LevelingSystem"):
		get_parent().get_node("LevelingSystem").recalculate_stats(false)

# ---------------------------------------------------------------------------
#  Inventar
# ---------------------------------------------------------------------------
func add_item(item_id: StringName, amount: int) -> bool:
	var item := Database.get_item(item_id)
	if item == null or amount <= 0:
		return false
	var remaining := amount
	# Erst existierende Stacks auffuellen.
	if item.is_stackable():
		for slot in slots:
			if slot["id"] == item_id and slot["amount"] < item.max_stack:
				var space := item.max_stack - slot["amount"]
				var add := mini(space, remaining)
				slot["amount"] += add
				remaining -= add
				if remaining <= 0:
					break
	# Neue Stacks anlegen.
	while remaining > 0 and slots.size() < MAX_SLOTS:
		var add := mini(item.max_stack, remaining)
		slots.append({"id": item_id, "amount": add})
		remaining -= add
	Events.inventory_changed.emit()
	if remaining > 0:
		Events.toast_message.emit("Inventar voll!")
		return false
	return true

func remove_item(item_id: StringName, amount: int) -> bool:
	var remaining := amount
	for i in range(slots.size() - 1, -1, -1):
		if slots[i]["id"] == item_id:
			var take := mini(slots[i]["amount"], remaining)
			slots[i]["amount"] -= take
			remaining -= take
			if slots[i]["amount"] <= 0:
				slots.remove_at(i)
			if remaining <= 0:
				break
	Events.inventory_changed.emit()
	return remaining <= 0

func count_item(item_id: StringName) -> int:
	var total := 0
	for slot in slots:
		if slot["id"] == item_id:
			total += slot["amount"]
	return total

func has_item(item_id: StringName, amount := 1) -> bool:
	return count_item(item_id) >= amount

# ---------------------------------------------------------------------------
#  Benutzung / Equipment
# ---------------------------------------------------------------------------
func use_item(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size():
		return
	var item := Database.get_item(slots[slot_index]["id"])
	if item == null:
		return
	match item.type:
		ItemData.ItemType.CONSUMABLE:
			_consume(item)
			remove_item(item.id, 1)
		ItemData.ItemType.WEAPON, ItemData.ItemType.ARMOR:
			equip_item(item.id)

func _consume(item: ItemData) -> void:
	var combat = _combat()
	if item.heal_amount > 0 and combat:
		combat.heal(item.heal_amount)
	if item.mana_amount > 0 and combat:
		combat.restore_mana(item.mana_amount)
	AudioManager.play_sfx("res://assets/audio/sfx_drink.ogg")

func equip_item(item_id: StringName) -> void:
	var item := Database.get_item(item_id)
	if item == null or not item.is_equippable():
		return
	var slot: int = item.equip_slot
	# Bereits ausgeruestetes Item zurueck ins Inventar.
	if equipment[slot] != &"":
		add_item(equipment[slot], 1)
	equipment[slot] = item_id
	remove_item(item_id, 1)
	Events.equipment_changed.emit()
	# Stats neu berechnen.
	if get_parent().has_node("LevelingSystem"):
		get_parent().get_node("LevelingSystem").recalculate_stats(false)
	AudioManager.play_sfx("res://assets/audio/sfx_equip.ogg")

func unequip(slot: int) -> void:
	if equipment.get(slot, &"") == &"":
		return
	add_item(equipment[slot], 1)
	equipment[slot] = &""
	Events.equipment_changed.emit()
	if get_parent().has_node("LevelingSystem"):
		get_parent().get_node("LevelingSystem").recalculate_stats(false)

func _combat():
	if get_parent().has_node("CombatSystem"):
		return get_parent().get_node("CombatSystem")
	return null

# ---------------------------------------------------------------------------
#  Save
# ---------------------------------------------------------------------------
func serialize() -> Dictionary:
	var slot_data: Array = []
	for s in slots:
		slot_data.append({"id": String(s["id"]), "amount": s["amount"]})
	var equip_data: Dictionary = {}
	for k in equipment:
		equip_data[str(k)] = String(equipment[k])
	return {"slots": slot_data, "equipment": equip_data}
