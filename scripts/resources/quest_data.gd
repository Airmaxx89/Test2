extends Resource
class_name QuestData
## Definition einer Quest inkl. Ziele, Belohnungen und Kette (naechste Quest).

enum ObjectiveType { KILL, COLLECT, ESCORT, TALK, REACH }

@export var id: StringName = &""
@export var title: String = "Quest"
@export_multiline var summary: String = ""
@export_multiline var completion_text: String = ""
@export var required_level: int = 1
@export var giver_npc_id: StringName = &""
@export var turnin_npc_id: StringName = &""     # leer -> gleicher wie giver

@export_group("Ziele")
## Jede Objective ist ein Dictionary:
## { "type": ObjectiveType, "target": StringName, "amount": int, "label": String }
## (Bewusst untypisiertes Array -> maximale Robustheit bei Literal-Zuweisung.)
@export var objectives: Array = []

@export_group("Belohnungen")
@export var reward_xp: int = 100
@export var reward_gold: int = 10
## Belohnungs-Items: [{ "id": StringName, "amount": int }]
@export var reward_items: Array = []
@export var next_quest_id: StringName = &""     # Quest-Kette

func objective_count() -> int:
	return objectives.size()
