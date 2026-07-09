extends Node
class_name CharacterModel
## Builds a smooth, rounded, articulated humanoid figure from built-in
## curved primitive meshes (Sphere/Capsule/Cylinder) - original geometry,
## no external model or texture assets. Curved primitives use interpolated
## per-vertex normals in Godot, which is what makes this read as a lit,
## rounded figure instead of a flat-shaded box stack.
## Limbs are pivot + mesh pairs (pivot at the joint, mesh hanging below it)
## so they swing naturally from the hip/shoulder in animate().

const HEAD_Y := 1.6
const HEAD_RADIUS := 0.21
const TORSO_Y := 1.05
const TORSO_HEIGHT := 0.7
const HIP_Y := 0.7
const SHOULDER_Y := 1.4
const LIMB_LENGTH := 0.7
const BOOT_COLOR := Color(0.16, 0.12, 0.09)


static func build(skin_color: Color, outfit_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"

	var legs := Node3D.new()
	legs.name = "Legs"
	root.add_child(legs)

	legs.add_child(_limb("LegLeft", outfit_color.darkened(0.2), Vector3(-0.13, HIP_Y, 0.0), BOOT_COLOR, true))
	legs.add_child(_limb("LegRight", outfit_color.darkened(0.2), Vector3(0.13, HIP_Y, 0.0), BOOT_COLOR, true))

	root.add_child(_torso(outfit_color))

	root.add_child(_limb("ArmLeft", skin_color, Vector3(-0.35, SHOULDER_Y, 0.0), skin_color, false))
	root.add_child(_limb("ArmRight", skin_color, Vector3(0.35, SHOULDER_Y, 0.0), skin_color, false))

	root.add_child(_head(skin_color))

	return root


static func _torso(color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Torso"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.26
	mesh.bottom_radius = 0.20
	mesh.height = TORSO_HEIGHT
	mesh.radial_segments = 12
	mesh.material = _material(color)
	mi.mesh = mesh
	mi.position = Vector3(0, TORSO_Y, 0)
	return mi


## Head is a small Node3D (not a bare mesh) so the eyes attach to it and it
## can nod independently during the idle animation.
static func _head(skin_color: Color) -> Node3D:
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, HEAD_Y, 0)

	var head_mesh := MeshInstance3D.new()
	head_mesh.name = "HeadMesh"
	var sphere := SphereMesh.new()
	sphere.radius = HEAD_RADIUS
	sphere.height = HEAD_RADIUS * 2.0
	sphere.radial_segments = 16
	sphere.rings = 10
	sphere.material = _material(skin_color)
	head_mesh.mesh = sphere
	head.add_child(head_mesh)

	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.05, 0.05, 0.08)
	eye_mat.roughness = 0.15

	var eye_angle := deg_to_rad(25.0)
	var eye_forward := cos(eye_angle) * HEAD_RADIUS * 0.95
	var eye_side := sin(eye_angle) * HEAD_RADIUS * 0.95
	var eye_up := HEAD_RADIUS * 0.15

	head.add_child(_eye("EyeLeft", eye_mat, Vector3(-eye_side, eye_up, eye_forward)))
	head.add_child(_eye("EyeRight", eye_mat, Vector3(eye_side, eye_up, eye_forward)))

	return head


static func _eye(node_name: String, mat: StandardMaterial3D, local_pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	sphere.radial_segments = 8
	sphere.rings = 6
	sphere.material = mat
	mi.mesh = sphere
	mi.position = local_pos
	return mi


## A limb is a pivot Node3D placed at the joint height, with a capsule mesh
## hanging straight down from it plus a small rounded hand/foot at the tip -
## rotating the pivot swings the whole limb (mesh + extremity) together,
## exactly like the old box-limb pivot did.
static func _limb(node_name: String, limb_color: Color, pivot_pos: Vector3, extremity_color: Color, is_leg: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pivot_pos

	var mesh := MeshInstance3D.new()
	mesh.name = node_name + "Mesh"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.11 if is_leg else 0.095
	capsule.height = LIMB_LENGTH
	capsule.radial_segments = 10
	capsule.rings = 4
	capsule.material = _material(limb_color)
	mesh.mesh = capsule
	mesh.position = Vector3(0, -LIMB_LENGTH / 2.0, 0)
	pivot.add_child(mesh)

	if is_leg:
		pivot.add_child(_foot(node_name + "Foot", extremity_color))
	else:
		pivot.add_child(_hand(node_name + "Hand", extremity_color))

	return pivot


static func _hand(node_name: String, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	sphere.radial_segments = 8
	sphere.rings = 6
	sphere.material = _material(color)
	mi.mesh = sphere
	mi.position = Vector3(0, -LIMB_LENGTH + 0.02, 0)
	return mi


## Squashed/elongated sphere reads as a rounded boot.
static func _foot(node_name: String, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 8
	sphere.rings = 6
	sphere.material = _material(color)
	mi.mesh = sphere
	mi.scale = Vector3(1.0, 0.55, 1.55)
	mi.position = Vector3(0, -LIMB_LENGTH + 0.035, 0.05)
	return mi


static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	return mat


## Drives a walk cycle (legs/arms swing contralaterally) while moving, or a
## subtle idle sway/breathing motion while standing still. idle_phase keeps
## incrementing regardless of movement (unlike walk_phase, which callers
## freeze when not moving) and defaults to 0.0 so old 3-argument call sites
## still compile and simply show no idle motion until updated.
static func animate(model: Node3D, walk_phase: float, is_moving: bool, idle_phase: float = 0.0) -> void:
	var leg_l: Node3D = model.get_node_or_null("Legs/LegLeft")
	var leg_r: Node3D = model.get_node_or_null("Legs/LegRight")
	var arm_l: Node3D = model.get_node_or_null("ArmLeft")
	var arm_r: Node3D = model.get_node_or_null("ArmRight")
	var head: Node3D = model.get_node_or_null("Head")
	var torso: Node3D = model.get_node_or_null("Torso")

	if is_moving:
		var swing := sin(walk_phase) * 0.55
		if leg_l:
			leg_l.rotation = Vector3(swing, 0, 0)
		if leg_r:
			leg_r.rotation = Vector3(-swing, 0, 0)
		if arm_l:
			arm_l.rotation = Vector3(-swing, 0, 0)
		if arm_r:
			arm_r.rotation = Vector3(swing, 0, 0)
		if torso:
			torso.scale.y = 1.0
		if head:
			head.position.y = HEAD_Y
	else:
		var breathe := sin(idle_phase * 1.6)
		if leg_l:
			leg_l.rotation = Vector3.ZERO
		if leg_r:
			leg_r.rotation = Vector3.ZERO
		if arm_l:
			arm_l.rotation = Vector3(0, 0, 0.05 + sin(idle_phase * 0.9) * 0.035)
		if arm_r:
			arm_r.rotation = Vector3(0, 0, -0.05 - sin(idle_phase * 0.9 + 0.4) * 0.035)
		if torso:
			torso.scale.y = 1.0 + breathe * 0.015
		if head:
			head.position.y = HEAD_Y + breathe * 0.008
