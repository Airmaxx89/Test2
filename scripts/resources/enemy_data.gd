extends Resource
class_name EnemyData
## Definition eines Gegner-Typs (Stats, Verhalten, Loot).

enum AttackStyle { MELEE, RANGED }

@export var id: StringName = &""
@export var display_name: String = "Enemy"
@export var body_color: Color = Color(0.7, 0.2, 0.2)
@export var level: int = 1
@export var attack_style: AttackStyle = AttackStyle.MELEE

@export_group("Stats")
@export var max_health: int = 50
@export var damage: int = 8
@export var move_speed: float = 3.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.5
@export var detection_radius: float = 12.0
@export var leash_radius: float = 20.0        # kehrt zum Spawn zurueck, wenn ueberschritten

@export_group("Belohnung")
@export var xp_reward: int = 25
@export var gold_min: int = 1
@export var gold_max: int = 5
## Loot: [{ "id": StringName, "chance": float(0..1), "min": int, "max": int }]
@export var loot_table: Array = []
## Fuer KILL-Quests relevanter Tag (z.B. &"wolf", &"bandit")
@export var quest_tag: StringName = &""
