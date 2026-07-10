extends Control
class_name Minimap
## Einfache prozedural gezeichnete Minimap (kein Kamera-Rendern -> billig).
## Zeigt Spieler (Pfeil), Gegner (rot), NPCs (gelb) und Quest-Ziele relativ zur
## Spielerposition. Draw-basiert via _draw(), aktualisiert in _process gedrosselt.

@export var world_range := 60.0        # Meter, die der Radius abdeckt
@export var update_interval := 0.1     # Sekunden zwischen Redraws (Performance)

var _player: Node3D
var _accum := 0.0
var _radius := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(150, 150)
	_radius = min(size.x, size.y) * 0.5

func _process(delta: float) -> void:
	_accum += delta
	if _accum >= update_interval:
		_accum = 0.0
		queue_redraw()

func _draw() -> void:
	_radius = min(size.x, size.y) * 0.5
	var center := size * 0.5
	# Hintergrund-Kreis.
	draw_circle(center, _radius, Color(0.08, 0.1, 0.12, 0.75))
	draw_arc(center, _radius, 0, TAU, 48, Color(0.4, 0.5, 0.55, 0.8), 2.0, true)

	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	var ppos := _player.global_position

	# Gegner (rot).
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and e is Node3D and not (e.has_method("is_dead") and e.is_dead()):
			_plot(center, ppos, e.global_position, Color(1, 0.3, 0.3), 3.0)
	# NPCs (gelb).
	for n in get_tree().get_nodes_in_group("npc"):
		if is_instance_valid(n) and n is Node3D:
			_plot(center, ppos, n.global_position, Color(1, 0.85, 0.2), 3.5)

	# Spieler (weisser Pfeil in der Mitte).
	draw_circle(center, 4.0, Color.WHITE)

func _plot(center: Vector2, origin: Vector3, target: Vector3, color: Color, r: float) -> void:
	var rel := target - origin
	var map_pos := Vector2(rel.x, rel.z) / world_range * _radius
	if map_pos.length() > _radius - 4.0:
		map_pos = map_pos.normalized() * (_radius - 4.0)   # am Rand clampen
	draw_circle(center + map_pos, r, color)
