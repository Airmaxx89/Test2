extends Node
## Globaler Event-Bus (Signal-Hub).
## Entkoppelt Systeme: Sender kennt Empfaenger nicht. Reduziert harte Referenzen
## und damit Kopplung -> leichter erweiterbar und performanter (keine get_node-Ketten).

# --- Combat ---
signal player_damaged(amount: int, current_hp: int, max_hp: int)
signal player_healed(amount: int, current_hp: int, max_hp: int)
signal player_mana_changed(current: int, maximum: int)
signal enemy_killed(enemy_data: EnemyData, position: Vector3)
signal damage_number(world_pos: Vector3, amount: int, is_crit: bool, to_player: bool)

# --- Progression ---
signal xp_gained(amount: int)
signal level_up(new_level: int)
signal stats_changed(stats: Dictionary)
signal skill_unlocked(skill_id: StringName)

# --- Quests ---
signal quest_offered(quest: QuestData)
signal quest_accepted(quest: QuestData)
signal quest_objective_updated(quest_id: StringName, objective_index: int, progress: int, total: int)
signal quest_ready_to_turnin(quest_id: StringName)
signal quest_completed(quest: QuestData)

# --- Inventar / Loot ---
signal item_added(item_id: StringName, amount: int)
signal item_removed(item_id: StringName, amount: int)
signal inventory_changed()
signal equipment_changed()
signal gold_changed(new_total: int)
signal loot_dropped(item_id: StringName, world_pos: Vector3)

# --- Skills / Hotbar ---
signal skill_used(slot: int, skill: SkillData)
signal skill_cooldown_started(slot: int, duration: float)

# --- Interaktion / UI ---
signal interactable_in_range(interactable: Node)
signal interactable_out_of_range(interactable: Node)
signal toast_message(text: String)
signal show_dialog(npc_name: String, lines: Array)

# --- Game-Flow ---
signal game_started()
signal game_paused(paused: bool)
signal player_ready(player: Node)
