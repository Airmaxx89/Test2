extends Resource
class_name ItemData
## Daten-Definition eines Items (Resource-basiert -> im Editor editierbar & speicherbar).
## Wird sowohl fuer Inventar-Stacks als auch fuer Equipment / Loot verwendet.

enum ItemType { MISC, CONSUMABLE, WEAPON, ARMOR, QUEST }
enum EquipSlot { NONE, WEAPON, HEAD, CHEST, TRINKET }

@export var id: StringName = &""            # Eindeutige ID, z.B. &"potion_health"
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var type: ItemType = ItemType.MISC
@export var icon: Texture2D                  # Platzhalter -> spaeter Kenney-Icon
@export var max_stack: int = 99
@export var vendor_value: int = 1

@export_group("Equipment")
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var bonus_strength: int = 0
@export var bonus_intellect: int = 0
@export var bonus_stamina: int = 0
@export var bonus_armor: int = 0
@export var weapon_damage: int = 0

@export_group("Consumable")
@export var heal_amount: int = 0
@export var mana_amount: int = 0

func is_equippable() -> bool:
	return equip_slot != EquipSlot.NONE

func is_stackable() -> bool:
	return max_stack > 1
