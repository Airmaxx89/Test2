extends Node
## Bridge between the touch UI (TouchControls) and gameplay code (Player).
## Decouples the UI, which is built independently in Main/HUD, from the
## Player instance, which is created later inside World.

var move_vector: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO

var jump_pressed: bool = false
var attack_pressed: bool = false
var interact_pressed: bool = false
var ability_requested: Array = [false, false, false]


func consume_jump() -> bool:
	if jump_pressed:
		jump_pressed = false
		return true
	return false


func consume_attack() -> bool:
	if attack_pressed:
		attack_pressed = false
		return true
	return false


func consume_interact() -> bool:
	if interact_pressed:
		interact_pressed = false
		return true
	return false


func consume_ability(index: int) -> bool:
	if index < ability_requested.size() and ability_requested[index]:
		ability_requested[index] = false
		return true
	return false


func consume_look() -> Vector2:
	var d := look_delta
	look_delta = Vector2.ZERO
	return d


func request_ability(index: int) -> void:
	if index < ability_requested.size():
		ability_requested[index] = true
