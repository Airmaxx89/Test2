extends StaticBody3D
class_name NPC
## Quest-giver / trainer NPCs. Shows a "!" marker for offerable quests and a
## "?" marker for ready turn-ins, like classic quest-log MMORPGs.

var npc_id: String
var display_name: String
var marker: Label3D


func setup(id: String, name_str: String) -> void:
	npc_id = id
	display_name = name_str

	var model := CharacterModel.build(Color(0.85, 0.7, 0.55), Color(0.45, 0.35, 0.55))
	add_child(model)

	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)

	var label := Label3D.new()
	label.text = display_name
	label.position = Vector3(0, 2.15, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.outline_size = 5
	add_child(label)

	marker = Label3D.new()
	marker.position = Vector3(0, 2.55, 0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 44
	marker.outline_size = 6
	add_child(marker)
	_update_marker()


func _process(_delta: float) -> void:
	_update_marker()


func _update_marker() -> void:
	if QuestManager.get_turn_in_quests_for_npc(npc_id).size() > 0:
		marker.text = "?"
		marker.modulate = Color(0.5, 0.85, 1.0)
	elif QuestManager.get_available_quests_for_npc(npc_id).size() > 0:
		marker.text = "!"
		marker.modulate = Color(1.0, 0.85, 0.2)
	else:
		marker.text = ""


func interact() -> void:
	DialogueState.trigger(npc_id, display_name)
