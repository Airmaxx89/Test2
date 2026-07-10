extends Node
## Zentrale Datenbank fuer alle statischen Spieldaten (Klassen, Skills, Items,
## Enemies, Quests). Laedt Resources einmalig beim Start -> schnelle Lookups
## per StringName-ID zur Laufzeit (kein wiederholtes load()).
##
## Damit das Projekt SOFORT ohne manuelles Anlegen von .tres laeuft, werden die
## Kern-Daten hier prozedural erzeugt (Code-defined defaults). Du kannst spaeter
## jederzeit .tres-Dateien in resources/ ablegen und hier per _load_dir einlesen.

var classes: Dictionary = {}     # StringName -> ClassData
var skills: Dictionary = {}      # StringName -> SkillData
var items: Dictionary = {}       # StringName -> ItemData
var enemies: Dictionary = {}     # StringName -> EnemyData
var quests: Dictionary = {}      # StringName -> QuestData

func _ready() -> void:
	_build_skills()
	_build_classes()
	_build_items()
	_build_enemies()
	_build_quests()
	# Optional: echte .tres-Resources ueberschreiben Defaults, falls vorhanden.
	_load_dir("res://resources/classes", classes)
	_load_dir("res://resources/items", items)
	_load_dir("res://resources/enemies", enemies)
	_load_dir("res://resources/quests", quests)

# ---------------------------------------------------------------------------
#  Lookups
# ---------------------------------------------------------------------------
func get_char_class(id: StringName) -> ClassData: return classes.get(id)
func get_skill(id: StringName) -> SkillData: return skills.get(id)
func get_item(id: StringName) -> ItemData: return items.get(id)
func get_enemy(id: StringName) -> EnemyData: return enemies.get(id)
func get_quest(id: StringName) -> QuestData: return quests.get(id)
func all_quests() -> Array: return quests.values()

# ---------------------------------------------------------------------------
#  Optionales Laden echter Resource-Dateien
# ---------------------------------------------------------------------------
func _load_dir(path: String, target: Dictionary) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir() and (f.ends_with(".tres") or f.ends_with(".res")):
			var res := load(path.path_join(f))
			if res and res.get("id") != null and res.id != &"":
				target[res.id] = res
		f = dir.get_next()
	dir.list_dir_end()

# ---------------------------------------------------------------------------
#  Prozedurale Default-Daten (damit alles sofort spielbar ist)
# ---------------------------------------------------------------------------
func _mk_skill(id: StringName, name: String, kind: int, mana: int, cd: float,
		rng: float, dmg: float, scale_stat: StringName, req: int,
		aoe := 0.0, heal := 0) -> SkillData:
	var s := SkillData.new()
	s.id = id; s.display_name = name; s.kind = kind
	s.mana_cost = mana; s.cooldown = cd; s.cast_range = rng
	s.base_damage = int(dmg); s.damage_scaling_stat = scale_stat
	s.scaling_factor = 1.0; s.required_level = req
	s.aoe_radius = aoe; s.heal_amount = heal
	return s

func _build_skills() -> void:
	# Warrior
	skills[&"heroic_strike"] = _mk_skill(&"heroic_strike", "Heldenschlag", SkillData.SkillKind.MELEE, 5, 3.0, 2.5, 18, &"strength", 1)
	skills[&"whirlwind"] = _mk_skill(&"whirlwind", "Wirbelwind", SkillData.SkillKind.AOE, 15, 8.0, 3.0, 14, &"strength", 3, 4.0)
	skills[&"charge"] = _mk_skill(&"charge", "Ansturm", SkillData.SkillKind.MELEE, 10, 10.0, 12.0, 10, &"strength", 6)
	skills[&"battle_shout"] = _mk_skill(&"battle_shout", "Kampfschrei (Heilung)", SkillData.SkillKind.HEAL, 20, 15.0, 0.0, 0, &"stamina", 9, 0.0, 40)
	# Mage
	skills[&"fireball"] = _mk_skill(&"fireball", "Feuerball", SkillData.SkillKind.PROJECTILE, 12, 3.0, 18.0, 22, &"intellect", 1)
	skills[&"frost_nova"] = _mk_skill(&"frost_nova", "Frostnova", SkillData.SkillKind.AOE, 18, 10.0, 4.0, 16, &"intellect", 3, 5.0)
	skills[&"arcane_bolt"] = _mk_skill(&"arcane_bolt", "Arkaner Blitz", SkillData.SkillKind.PROJECTILE, 8, 2.0, 20.0, 14, &"intellect", 6)
	skills[&"lesser_heal"] = _mk_skill(&"lesser_heal", "Geringe Heilung", SkillData.SkillKind.HEAL, 15, 8.0, 0.0, 0, &"intellect", 9, 0.0, 50)

func _build_classes() -> void:
	var warrior := ClassData.new()
	warrior.id = &"warrior"; warrior.display_name = "Krieger"
	warrior.description = "Robuster Nahkaempfer. Hohe Lebenspunkte und Ruestung."
	warrior.body_color = Color(0.75, 0.35, 0.25)
	warrior.base_health = 140; warrior.base_mana = 40
	warrior.base_strength = 14; warrior.base_intellect = 6; warrior.base_stamina = 14
	warrior.health_per_level = 26; warrior.mana_per_level = 6
	warrior.strength_per_level = 3; warrior.intellect_per_level = 1; warrior.stamina_per_level = 3
	warrior.primary_stat = &"strength"
	warrior.starter_skill_ids = [&"heroic_strike"]
	warrior.skill_unlocks = {3: &"whirlwind", 6: &"charge", 9: &"battle_shout"}
	classes[warrior.id] = warrior

	var mage := ClassData.new()
	mage.id = &"mage"; mage.display_name = "Magier"
	mage.description = "Zerbrechlicher Fernkaempfer mit hohem Zauberschaden."
	mage.body_color = Color(0.3, 0.4, 0.85)
	mage.base_health = 90; mage.base_mana = 90
	mage.base_strength = 6; mage.base_intellect = 16; mage.base_stamina = 9
	mage.health_per_level = 16; mage.mana_per_level = 16
	mage.strength_per_level = 1; mage.intellect_per_level = 3; mage.stamina_per_level = 2
	mage.primary_stat = &"intellect"
	mage.starter_skill_ids = [&"fireball"]
	mage.skill_unlocks = {3: &"frost_nova", 6: &"arcane_bolt", 9: &"lesser_heal"}
	classes[mage.id] = mage

func _mk_item(id: StringName, name: String, type: int, stack: int, val: int) -> ItemData:
	var it := ItemData.new()
	it.id = id; it.display_name = name; it.type = type
	it.max_stack = stack; it.vendor_value = val
	return it

func _build_items() -> void:
	var pot := _mk_item(&"potion_health", "Heiltrank", ItemData.ItemType.CONSUMABLE, 20, 5)
	pot.description = "Stellt sofort 60 Lebenspunkte wieder her."
	pot.heal_amount = 60
	items[pot.id] = pot

	var mpot := _mk_item(&"potion_mana", "Manatrank", ItemData.ItemType.CONSUMABLE, 20, 5)
	mpot.description = "Stellt sofort 50 Mana wieder her."
	mpot.mana_amount = 50
	items[mpot.id] = mpot

	var sword := _mk_item(&"iron_sword", "Eisenschwert", ItemData.ItemType.WEAPON, 1, 25)
	sword.description = "Ein solides Schwert."
	sword.equip_slot = ItemData.EquipSlot.WEAPON
	sword.weapon_damage = 8; sword.bonus_strength = 3
	items[sword.id] = sword

	var staff := _mk_item(&"apprentice_staff", "Lehrlingsstab", ItemData.ItemType.WEAPON, 1, 25)
	staff.description = "Ein einfacher Zauberstab."
	staff.equip_slot = ItemData.EquipSlot.WEAPON
	staff.weapon_damage = 4; staff.bonus_intellect = 4
	items[staff.id] = staff

	var helm := _mk_item(&"leather_helm", "Lederkappe", ItemData.ItemType.ARMOR, 1, 15)
	helm.equip_slot = ItemData.EquipSlot.HEAD; helm.bonus_armor = 5; helm.bonus_stamina = 2
	items[helm.id] = helm

	var chest := _mk_item(&"leather_vest", "Lederweste", ItemData.ItemType.ARMOR, 1, 20)
	chest.equip_slot = ItemData.EquipSlot.CHEST; chest.bonus_armor = 10; chest.bonus_stamina = 4
	items[chest.id] = chest

	# Quest-Items
	var pelt := _mk_item(&"wolf_pelt", "Wolfsfell", ItemData.ItemType.QUEST, 99, 0)
	pelt.description = "Ein zottiges Wolfsfell. Von Foerster Aldric gesucht."
	items[pelt.id] = pelt

	var herb := _mk_item(&"moonleaf", "Mondblatt", ItemData.ItemType.QUEST, 99, 0)
	herb.description = "Ein leuchtendes Kraut aus den Ruinen."
	items[herb.id] = herb

	var relic := _mk_item(&"ancient_relic", "Uraltes Relikt", ItemData.ItemType.QUEST, 1, 0)
	relic.description = "Ein pulsierendes Artefakt aus der Tiefe der Ruinen."
	items[relic.id] = relic

func _mk_enemy(id: StringName, name: String, lvl: int, hp: int, dmg: int,
		style: int, xp: int, color: Color, tag: StringName) -> EnemyData:
	var e := EnemyData.new()
	e.id = id; e.display_name = name; e.level = lvl
	e.max_health = hp; e.damage = dmg; e.attack_style = style
	e.xp_reward = xp; e.body_color = color; e.quest_tag = tag
	e.gold_min = lvl; e.gold_max = lvl * 3
	return e

func _build_enemies() -> void:
	var wolf := _mk_enemy(&"wolf", "Grauwolf", 2, 45, 7, EnemyData.AttackStyle.MELEE, 22, Color(0.5,0.5,0.55), &"wolf")
	wolf.move_speed = 4.2; wolf.attack_range = 2.0; wolf.detection_radius = 12.0
	wolf.loot_table = [
		{"id": &"wolf_pelt", "chance": 0.8, "min": 1, "max": 1},
		{"id": &"potion_health", "chance": 0.15, "min": 1, "max": 1},
	]
	enemies[wolf.id] = wolf

	var bandit := _mk_enemy(&"bandit", "Waldbandit", 4, 70, 11, EnemyData.AttackStyle.MELEE, 40, Color(0.4,0.25,0.2), &"bandit")
	bandit.move_speed = 3.4; bandit.attack_range = 2.2
	bandit.loot_table = [
		{"id": &"potion_health", "chance": 0.25, "min": 1, "max": 2},
		{"id": &"iron_sword", "chance": 0.08, "min": 1, "max": 1},
		{"id": &"leather_helm", "chance": 0.1, "min": 1, "max": 1},
	]
	enemies[bandit.id] = bandit

	var archer := _mk_enemy(&"bandit_archer", "Banditen-Schuetze", 5, 55, 13, EnemyData.AttackStyle.RANGED, 50, Color(0.35,0.3,0.15), &"bandit")
	archer.move_speed = 3.0; archer.attack_range = 15.0; archer.attack_cooldown = 2.0
	archer.loot_table = [
		{"id": &"potion_mana", "chance": 0.25, "min": 1, "max": 2},
		{"id": &"leather_vest", "chance": 0.1, "min": 1, "max": 1},
	]
	enemies[archer.id] = archer

	var wraith := _mk_enemy(&"ruin_wraith", "Ruinengeist", 7, 120, 18, EnemyData.AttackStyle.RANGED, 90, Color(0.5,0.2,0.7), &"wraith")
	wraith.move_speed = 3.2; wraith.attack_range = 14.0; wraith.detection_radius = 14.0
	wraith.loot_table = [
		{"id": &"moonleaf", "chance": 0.7, "min": 1, "max": 2},
		{"id": &"apprentice_staff", "chance": 0.12, "min": 1, "max": 1},
	]
	enemies[wraith.id] = wraith

	var overlord := _mk_enemy(&"bandit_overlord", "Banditen-Anfuehrer", 9, 320, 24, EnemyData.AttackStyle.MELEE, 300, Color(0.6,0.1,0.1), &"boss")
	overlord.move_speed = 3.6; overlord.detection_radius = 16.0; overlord.leash_radius = 30.0
	overlord.loot_table = [
		{"id": &"ancient_relic", "chance": 1.0, "min": 1, "max": 1},
		{"id": &"iron_sword", "chance": 0.5, "min": 1, "max": 1},
		{"id": &"leather_vest", "chance": 0.5, "min": 1, "max": 1},
	]
	enemies[overlord.id] = overlord

func _mk_obj(type: int, target: StringName, amount: int, label: String) -> Dictionary:
	return {"type": type, "target": target, "amount": amount, "label": label}

func _build_quests() -> void:
	# 1) TALK / Intro
	var q1 := QuestData.new()
	q1.id = &"q_welcome"; q1.title = "Ankunft in Eichenhain"
	q1.summary = "Sprich mit Foerster Aldric im Dorf."
	q1.completion_text = "Willkommen, Reisender. Die Waelder sind gefaehrlich geworden."
	q1.giver_npc_id = &"aldric"; q1.required_level = 1
	q1.objectives = [_mk_obj(QuestData.ObjectiveType.TALK, &"aldric", 1, "Sprich mit Aldric")]
	q1.reward_xp = 50; q1.reward_gold = 10
	q1.next_quest_id = &"q_wolves"
	quests[q1.id] = q1

	# 2) KILL
	var q2 := QuestData.new()
	q2.id = &"q_wolves"; q2.title = "Wolfsplage"
	q2.summary = "Toete 6 Grauwoelfe, die das Dorf bedrohen."
	q2.completion_text = "Gute Arbeit! Die Herde sollte nun kleiner sein."
	q2.giver_npc_id = &"aldric"; q2.required_level = 1
	q2.objectives = [_mk_obj(QuestData.ObjectiveType.KILL, &"wolf", 6, "Grauwoelfe getoetet")]
	q2.reward_xp = 220; q2.reward_gold = 25
	q2.reward_items = [{"id": &"potion_health", "amount": 3}]
	q2.next_quest_id = &"q_pelts"
	quests[q2.id] = q2

	# 3) COLLECT
	var q3 := QuestData.new()
	q3.id = &"q_pelts"; q3.title = "Warme Felle"
	q3.summary = "Sammle 5 Wolfsfelle fuer den Winter."
	q3.completion_text = "Diese Felle halten das Dorf warm. Danke!"
	q3.giver_npc_id = &"aldric"; q3.required_level = 2
	q3.objectives = [_mk_obj(QuestData.ObjectiveType.COLLECT, &"wolf_pelt", 5, "Wolfsfelle gesammelt")]
	q3.reward_xp = 260; q3.reward_gold = 30
	q3.reward_items = [{"id": &"leather_vest", "amount": 1}]
	q3.next_quest_id = &"q_escort"
	quests[q3.id] = q3

	# 4) ESCORT
	var q4 := QuestData.new()
	q4.id = &"q_escort"; q4.title = "Sicheres Geleit"
	q4.summary = "Begleite die Haendlerin Mira sicher zu den Ruinen."
	q4.completion_text = "Danke fuer den Schutz! Ohne dich haetten die Banditen mich erwischt."
	q4.giver_npc_id = &"mira"; q4.required_level = 3
	q4.objectives = [_mk_obj(QuestData.ObjectiveType.ESCORT, &"mira", 1, "Mira zu den Ruinen begleiten")]
	q4.reward_xp = 340; q4.reward_gold = 45
	q4.next_quest_id = &"q_herbs"
	quests[q4.id] = q4

	# 5) COLLECT (Ruinen)
	var q5 := QuestData.new()
	q5.id = &"q_herbs"; q5.title = "Mondblatt-Ernte"
	q5.summary = "Sammle 6 Mondblaetter von den Ruinengeistern."
	q5.completion_text = "Diese Kraeuter sind maechtig. Sei vorsichtig da drin."
	q5.giver_npc_id = &"mira"; q5.required_level = 4
	q5.objectives = [_mk_obj(QuestData.ObjectiveType.COLLECT, &"moonleaf", 6, "Mondblaetter gesammelt")]
	q5.reward_xp = 420; q5.reward_gold = 55
	q5.reward_items = [{"id": &"potion_mana", "amount": 3}]
	q5.next_quest_id = &"q_bandits"
	quests[q5.id] = q5

	# 6) KILL (Banditen)
	var q6 := QuestData.new()
	q6.id = &"q_bandits"; q6.title = "Banditen-Saeuberung"
	q6.summary = "Toete 8 Banditen in den Ruinen."
	q6.completion_text = "Die Ruinen sind sicherer. Doch der Anfuehrer lebt noch..."
	q6.giver_npc_id = &"mira"; q6.required_level = 5
	q6.objectives = [_mk_obj(QuestData.ObjectiveType.KILL, &"bandit", 8, "Banditen getoetet")]
	q6.reward_xp = 620; q6.reward_gold = 70
	q6.next_quest_id = &"q_boss"
	quests[q6.id] = q6

	# 7) BOSS KILL + COLLECT
	var q7 := QuestData.new()
	q7.id = &"q_boss"; q7.title = "Das uralte Relikt"
	q7.summary = "Besiege den Banditen-Anfuehrer und bring das Relikt zurueck."
	q7.completion_text = "Du hast Eichenhain gerettet. Deine Legende beginnt hier."
	q7.giver_npc_id = &"aldric"; q7.required_level = 7
	q7.objectives = [
		_mk_obj(QuestData.ObjectiveType.KILL, &"boss", 1, "Anfuehrer besiegt"),
		_mk_obj(QuestData.ObjectiveType.COLLECT, &"ancient_relic", 1, "Relikt geborgen"),
	]
	q7.reward_xp = 1200; q7.reward_gold = 200
	q7.reward_items = [{"id": &"iron_sword", "amount": 1}]
	quests[q7.id] = q7
