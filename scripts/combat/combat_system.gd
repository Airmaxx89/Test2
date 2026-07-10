extends Node
class_name CombatSystem
## Kampf-Logik des Spielers (als Kind-Node am Player).
## - Auto-Attack auf naechstes Ziel in Reichweite
## - Skill-Ausfuehrung mit Cooldowns & Mana-Kosten (Hotbar-Slots 0..5)
## - Schaden austeilen (Melee/AOE/Projektil/Heal)
## - Schaden einstecken (Armor-Mitigation) + Tod

signal died()

const AUTO_ATTACK_INTERVAL := 1.2
const AUTO_ATTACK_RANGE := 2.5

# Cooldown-Restzeiten je Hotbar-Slot.
var _cooldowns := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var _hotbar: Array = []                       # Skill-IDs je Slot (StringName)
var _auto_attack_timer := 0.0
var auto_attack_enabled := true

@onready var _player: CharacterBody3D = get_parent()

func _ready() -> void:
	refresh_hotbar()
	Events.skill_unlocked.connect(func(_id): refresh_hotbar())

func _physics_process(delta: float) -> void:
	# Cooldowns herunterzaehlen.
	for i in _cooldowns.size():
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)

	# Auto-Attack.
	if auto_attack_enabled:
		_auto_attack_timer -= delta
		if _auto_attack_timer <= 0.0:
			var target := _find_nearest_enemy(AUTO_ATTACK_RANGE)
			if target:
				_do_melee_hit(target, _base_attack_damage())
				_auto_attack_timer = AUTO_ATTACK_INTERVAL
				AudioManager.play_sfx("res://assets/audio/sfx_hit.ogg", -4.0, randf_range(0.9, 1.1))
			else:
				_auto_attack_timer = 0.2   # haeufiger nach Ziel suchen, wenn keins da

## Belegt die Hotbar mit den freigeschalteten Skills der Klasse.
func refresh_hotbar() -> void:
	_hotbar = GameManager.character["unlocked_skills"].duplicate()
	Events.equipment_changed.emit()   # UI-Refresh anstoßen

func get_hotbar() -> Array:
	return _hotbar

func get_cooldown_ratio(slot: int) -> float:
	if slot >= _hotbar.size():
		return 0.0
	var sk := Database.get_skill(_hotbar[slot])
	if sk == null or sk.cooldown <= 0.0:
		return 0.0
	return _cooldowns[slot] / sk.cooldown

## Fuehrt den Skill in einem Hotbar-Slot aus (von UI-Button / Taste getriggert).
func use_skill(slot: int) -> void:
	if slot < 0 or slot >= _hotbar.size():
		return
	if _cooldowns[slot] > 0.0:
		return
	var sk := Database.get_skill(_hotbar[slot])
	if sk == null:
		return
	var char := GameManager.character
	if char["current_mana"] < sk.mana_cost:
		Events.toast_message.emit("Nicht genug Mana")
		return
	# Mana abziehen.
	char["current_mana"] -= sk.mana_cost
	Events.player_mana_changed.emit(char["current_mana"], char["stats"].get(&"max_mana", 0))
	# Cooldown starten.
	_cooldowns[slot] = sk.cooldown
	Events.skill_cooldown_started.emit(slot, sk.cooldown)
	Events.skill_used.emit(slot, sk)
	_execute_skill(sk)

func _execute_skill(sk: SkillData) -> void:
	var stats: Dictionary = GameManager.character["stats"]
	var dmg := sk.compute_damage(stats)
	match sk.kind:
		SkillData.SkillKind.MELEE:
			var target := _find_nearest_enemy(sk.cast_range)
			if target:
				# Charge: erst zum Ziel bewegen (vereinfacht: teleport-lunge).
				if sk.id == &"charge":
					_player.global_position = _player.global_position.move_toward(
						target.global_position, sk.cast_range - 1.0)
				_do_melee_hit(target, dmg)
			AudioManager.play_sfx("res://assets/audio/sfx_swing.ogg")
		SkillData.SkillKind.AOE:
			_do_aoe_hit(_player.global_position, sk.aoe_radius, dmg)
			AudioManager.play_sfx("res://assets/audio/sfx_aoe.ogg")
		SkillData.SkillKind.PROJECTILE:
			_spawn_projectile(sk, dmg)
			AudioManager.play_sfx("res://assets/audio/sfx_cast.ogg")
		SkillData.SkillKind.HEAL:
			heal(sk.heal_amount)
			AudioManager.play_sfx("res://assets/audio/sfx_heal.ogg")
		SkillData.SkillKind.BUFF:
			pass

# ---------------------------------------------------------------------------
#  Schaden austeilen
# ---------------------------------------------------------------------------
func _base_attack_damage() -> int:
	var stats: Dictionary = GameManager.character["stats"]
	var weapon: int = stats.get(&"weapon_damage", 0)
	var primary := GameManager.get_class_data().primary_stat if GameManager.get_class_data() else &"strength"
	return 4 + weapon + int(stats.get(primary, 0) * 0.5)

func _do_melee_hit(target: Node, dmg: int) -> void:
	if target and target.has_method("take_damage"):
		var crit := randf() < 0.15
		var final := int(dmg * (1.75 if crit else 1.0))
		target.take_damage(final, _player)
		Events.damage_number.emit(target.global_position + Vector3.UP * 1.5, final, crit, false)

func _do_aoe_hit(center: Vector3, radius: float, dmg: int) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e is Node3D:
			continue
		if center.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
			e.take_damage(dmg, _player)
			Events.damage_number.emit(e.global_position + Vector3.UP * 1.5, dmg, false, false)

func _spawn_projectile(sk: SkillData, dmg: int) -> void:
	# Ziel bestimmen: naechster Gegner in Reichweite, sonst Blickrichtung.
	var target := _find_nearest_enemy(sk.cast_range)
	var origin: Vector3 = _player.global_position + Vector3.UP * 1.2
	var dir: Vector3
	if target:
		dir = (target.global_position + Vector3.UP - origin).normalized()
	else:
		dir = -_player.global_transform.basis.z
	var proj := PoolManager.acquire(sk.projectile_scene_path)
	# In den World-Root haengen (nicht an den Spieler, damit es unabhaengig fliegt).
	_player.get_parent().add_child(proj)
	proj.setup(origin, dir, dmg, "enemies", _player)

# ---------------------------------------------------------------------------
#  Ziel-Findung
# ---------------------------------------------------------------------------
func _find_nearest_enemy(max_range: float) -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := max_range
	var ppos: Vector3 = _player.global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or not e is Node3D:
			continue
		if e.has_method("is_dead") and e.is_dead():
			continue
		var d := ppos.distance_to(e.global_position)
		if d <= nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

# ---------------------------------------------------------------------------
#  Schaden einstecken / Heilung (Spieler)
# ---------------------------------------------------------------------------
func take_damage(amount: int, _source: Node = null) -> void:
	var char := GameManager.character
	var stats: Dictionary = char["stats"]
	# Armor-Mitigation: einfache Formel (Armor / (Armor + 50)).
	var armor: int = stats.get(&"armor", 0)
	var mitigation := float(armor) / float(armor + 50)
	var final := maxi(1, int(amount * (1.0 - mitigation)))
	char["current_health"] = maxi(0, char["current_health"] - final)
	Events.player_damaged.emit(final, char["current_health"], stats.get(&"max_health", 1))
	Events.damage_number.emit(_player.global_position + Vector3.UP * 2.0, final, false, true)
	AudioManager.play_sfx("res://assets/audio/sfx_player_hurt.ogg")
	if char["current_health"] <= 0:
		died.emit()

func heal(amount: int) -> void:
	var char := GameManager.character
	var stats: Dictionary = char["stats"]
	var max_hp: int = stats.get(&"max_health", 1)
	char["current_health"] = mini(max_hp, char["current_health"] + amount)
	Events.player_healed.emit(amount, char["current_health"], max_hp)
	if amount > 0:
		Events.damage_number.emit(_player.global_position + Vector3.UP * 2.0, amount, false, false)

func restore_mana(amount: int) -> void:
	var char := GameManager.character
	var max_mp: int = char["stats"].get(&"max_mana", 1)
	char["current_mana"] = mini(max_mp, char["current_mana"] + amount)
	Events.player_mana_changed.emit(char["current_mana"], max_mp)
