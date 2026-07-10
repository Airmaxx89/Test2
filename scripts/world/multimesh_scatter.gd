extends MultiMeshInstance3D
class_name MultiMeshScatter
## Streut viele Instanzen (Baeume/Felsen/Gras) als EIN MultiMesh -> 1 Draw Call
## statt hunderter einzelner MeshInstances. Ideal fuer Mobile-Performance.
## Positionen werden deterministisch (Seed) im Bereich verteilt, mit Aussparung
## um das Dorf-Zentrum (clear_radius), damit nichts im Spawn steht.

@export var instance_count := 120
@export var area_size := Vector2(180, 180)   # Streuflaeche (X,Z) in Metern
@export var clear_center := Vector3.ZERO
@export var clear_radius := 12.0
@export var y_offset := 0.0
@export var scale_min := 0.8
@export var scale_max := 1.6
@export var random_seed := 12345

func _ready() -> void:
	if multimesh == null:
		push_warning("MultiMeshScatter: kein MultiMesh zugewiesen.")
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	multimesh.instance_count = instance_count
	var placed := 0
	var attempts := 0
	while placed < instance_count and attempts < instance_count * 4:
		attempts += 1
		var x := rng.randf_range(-area_size.x * 0.5, area_size.x * 0.5)
		var z := rng.randf_range(-area_size.y * 0.5, area_size.y * 0.5)
		var pos := Vector3(x, y_offset, z)
		# Aussparung um Dorf-Zentrum.
		if Vector2(x - clear_center.x, z - clear_center.z).length() < clear_radius:
			continue
		var s := rng.randf_range(scale_min, scale_max)
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3(s, s, s))
		multimesh.set_instance_transform(placed, Transform3D(basis, pos))
		placed += 1
	# Ungenutzte Instanzen (falls Abbruch) verstecken.
	multimesh.visible_instance_count = placed
