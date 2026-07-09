extends Node
class_name CharacterModel
## Builds a simple blocky (Minecraft-style) humanoid figure from primitive
## box meshes - original geometry, no external model or texture assets.
## Limbs are built as pivot + mesh pairs (pivot at the joint, mesh hanging
## below it) so they can swing naturally from the hip/shoulder in animate().

static func build(skin_color: Color, outfit_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"

	var legs := Node3D.new()
	legs.name = "Legs"
	root.add_child(legs)

	var leg_l := _limb("LegLeft", Vector3(0.22, 0.7, 0.22), outfit_color.darkened(0.2), Vector3(-0.13, 0.7, 0.0))
	legs.add_child(leg_l)

	var leg_r := _limb("LegRight", Vector3(0.22, 0.7, 0.22), outfit_color.darkened(0.2), Vector3(0.13, 0.7, 0.0))
	legs.add_child(leg_r)

	var torso := _box("Torso", Vector3(0.5, 0.7, 0.28), outfit_color)
	torso.position = Vector3(0, 1.05, 0)
	root.add_child(torso)

	var arm_l := _limb("ArmLeft", Vector3(0.2, 0.7, 0.2), skin_color, Vector3(-0.35, 1.4, 0.0))
	root.add_child(arm_l)

	var arm_r := _limb("ArmRight", Vector3(0.2, 0.7, 0.2), skin_color, Vector3(0.35, 1.4, 0.0))
	root.add_child(arm_r)

	var head := _box("Head", Vector3(0.42, 0.42, 0.42), skin_color)
	head.position = Vector3(0, 1.6, 0)
	root.add_child(head)

	return root


## A limb is a pivot Node3D placed at the joint height, with the visual box
## as its child hanging straight down from that pivot - rotating the pivot
## swings the whole limb like a real hip/shoulder joint instead of see-
## sawing through its own middle.
static func _limb(node_name: String, size: Vector3, color: Color, pivot_pos: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = node_name
	pivot.position = pivot_pos
	var mesh := _box(node_name + "Mesh", size, color)
	mesh.position = Vector3(0, -size.y / 2.0, 0)
	pivot.add_child(mesh)
	return pivot


static func _box(node_name: String, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	box.material = mat
	mi.mesh = box
	return mi


## Drives a simple walk-cycle: legs/arms swing oppositely (contralateral
## gait), settling back to a neutral pose when not moving.
static func animate(model: Node3D, walk_phase: float, is_moving: bool) -> void:
	var swing := sin(walk_phase) * 0.55 if is_moving else 0.0
	var leg_l: Node3D = model.get_node_or_null("Legs/LegLeft")
	var leg_r: Node3D = model.get_node_or_null("Legs/LegRight")
	var arm_l: Node3D = model.get_node_or_null("ArmLeft")
	var arm_r: Node3D = model.get_node_or_null("ArmRight")
	if leg_l:
		leg_l.rotation.x = swing
	if leg_r:
		leg_r.rotation.x = -swing
	if arm_l:
		arm_l.rotation.x = -swing
	if arm_r:
		arm_r.rotation.x = swing
