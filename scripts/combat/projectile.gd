extends Area3D
class_name Projectile
## Poolbares Projektil (Feuerball, Pfeil, arkaner Blitz).
## Wird von PoolManager verwaltet -> nutzt _on_pool_acquire/_release statt free.

@export var speed := 22.0
@export var lifetime := 3.0
@export var hit_effect_path := "res://scenes/combat/hit_effect.tscn"

var _dir := Vector3.FORWARD
var _damage := 0
var _target_group := "enemies"
var _source: Node = null
var _life := 0.0
var _active := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

## Initialisiert das Projektil beim Abschuss.
func setup(origin: Vector3, direction: Vector3, damage: int, target_group: String, source: Node) -> void:
	global_position = origin
	_dir = direction.normalized()
	_damage = damage
	_target_group = target_group
	_source = source
	_life = 0.0
	_active = true
	visible = true
	set_physics_process(true)
	# Nach Flugrichtung ausrichten.
	if _dir.length() > 0.01:
		look_at(origin + _dir, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position += _dir * speed * delta
	_life += delta
	if _life >= lifetime:
		_despawn()

func _on_body_entered(body: Node) -> void:
	_try_hit(body)

func _on_area_entered(area: Node) -> void:
	_try_hit(area)

func _try_hit(node: Node) -> void:
	if not _active or node == _source:
		return
	# Kollision mit Zielgruppe -> Schaden.
	if node.is_in_group(_target_group) and node.has_method("take_damage"):
		node.take_damage(_damage, _source)
		var to_player := _target_group == "player"
		Events.damage_number.emit(node.global_position + Vector3.UP * 1.5, _damage, false, to_player)
		_spawn_hit_effect()
		_despawn()
	elif node.is_in_group("world"):
		# Gegen Welt/Hindernis -> zerplatzen.
		_spawn_hit_effect()
		_despawn()

func _spawn_hit_effect() -> void:
	if ResourceLoader.exists(hit_effect_path):
		var fx := PoolManager.acquire(hit_effect_path)
		get_parent().add_child(fx)
		if fx is Node3D:
			fx.global_position = global_position

func _despawn() -> void:
	_active = false
	PoolManager.release(self)

# --- Pool-Hooks ---
func _on_pool_acquire() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func _on_pool_release() -> void:
	_active = false
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
