extends Node3D
class_name HealthBar3D
## Schwebende Gegner-Lebensleiste aus zwei QuadMesh-Quads (kein Texture-Bedarf).
## "BG" = dunkler Hintergrund, "Fill" = farbiger HP-Balken (X-Scale = HP-Ratio).
## Beide Quads sind unshaded + billboarded (in der Szene konfiguriert).

@onready var _fill: MeshInstance3D = get_node_or_null("Fill")

func _ready() -> void:
	# Material pro Instanz eindeutig machen, damit die Farbe nicht global geteilt wird.
	if _fill and _fill.material_override:
		_fill.material_override = _fill.material_override.duplicate()

func set_ratio(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if _fill:
		# Balken von links skalieren: Quad linksbuendig verschieben und skalieren.
		_fill.scale.x = maxf(0.001, ratio)
		_fill.position.x = -0.5 * (1.0 - ratio)
		var mat := _fill.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = Color(1.0 - ratio * 0.2, 0.2 + ratio * 0.7, 0.2)
	# Voll => ausblenden (weniger Overdraw); bei Schaden anzeigen.
	visible = ratio < 0.999
