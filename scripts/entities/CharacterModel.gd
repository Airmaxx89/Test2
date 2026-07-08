extends Node
class_name CharacterModel
## Builds a simple blocky (Minecraft-style) humanoid figure from primitive
## box meshes - original geometry, no external model or texture assets.

static func build(skin_color: Color, outfit_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"

	var legs := Node3D.new()
	legs.name = "Legs"
	root.add_child(legs)

	var leg_l := _box("LegLeft", Vector3(0.22, 0.7, 0.22), outfit_color.darkened(0.2))
	leg_l.position = Vector3(-0.13, 0.35, 0.0)
	legs.add_child(leg_l)

	var leg_r := _box("LegRight", Vector3(0.22, 0.7, 0.22), outfit_color.darkened(0.2))
	leg_r.position = Vector3(0.13, 0.35, 0.0)
	legs.add_child(leg_r)

	var torso := _box("Torso", Vector3(0.5, 0.7, 0.28), outfit_color)
	torso.position = Vector3(0, 1.05, 0)
	root.add_child(torso)

	var arm_l := _box("ArmLeft", Vector3(0.2, 0.7, 0.2), skin_color)
	arm_l.position = Vector3(-0.35, 1.05, 0)
	root.add_child(arm_l)

	var arm_r := _box("ArmRight", Vector3(0.2, 0.7, 0.2), skin_color)
	arm_r.position = Vector3(0.35, 1.05, 0)
	root.add_child(arm_r)

	var head := _box("Head", Vector3(0.42, 0.42, 0.42), skin_color)
	head.position = Vector3(0, 1.6, 0)
	root.add_child(head)

	return root


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
