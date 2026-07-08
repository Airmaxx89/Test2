extends CanvasLayer
class_name TouchControls
## Mobile touch input: a floating virtual joystick on the left half of the
## screen for movement, drag-to-look on the right half, and action buttons.
## Falls back to mouse automatically because emulate_touch_from_mouse is on.

var joystick_base: Control
var joystick_knob: Control
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
const JOYSTICK_RADIUS := 65.0

var camera_touch_index: int = -1

var buttons: Array = []
var ability_buttons: Array = []


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	joystick_base = _make_panel(Vector2(140, 140), Color(1, 1, 1, 0.12))
	joystick_base.visible = false
	root.add_child(joystick_base)

	joystick_knob = _make_panel(Vector2(56, 56), Color(1, 1, 1, 0.35))
	joystick_knob.visible = false
	root.add_child(joystick_knob)

	var jump_btn := _make_button("Springen", Vector2(96, 64))
	jump_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jump_btn.position = Vector2(-260, -180)
	jump_btn.pressed.connect(func(): InputState.jump_pressed = true)
	root.add_child(jump_btn)
	buttons.append(jump_btn)

	var interact_btn := _make_button("Interagieren", Vector2(150, 56))
	interact_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	interact_btn.position = Vector2(-260, -240)
	interact_btn.pressed.connect(func(): InputState.interact_pressed = true)
	root.add_child(interact_btn)
	buttons.append(interact_btn)

	var attack_btn := _make_button("Angriff", Vector2(110, 110))
	attack_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	attack_btn.position = Vector2(-130, -140)
	attack_btn.pressed.connect(func(): InputState.attack_pressed = true)
	root.add_child(attack_btn)
	buttons.append(attack_btn)

	for i in range(3):
		var ab_btn := _make_button("F%d" % (i + 1), Vector2(70, 70))
		ab_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		ab_btn.position = Vector2(-130 - (i + 1) * 80, -260)
		ab_btn.pressed.connect(_make_ability_callback(i))
		root.add_child(ab_btn)
		buttons.append(ab_btn)
		ability_buttons.append(ab_btn)


func _make_ability_callback(idx: int) -> Callable:
	return func(): InputState.request_ability(idx)


func _make_panel(size: Vector2, color: Color) -> ColorRect:
	var p := ColorRect.new()
	p.color = color
	p.custom_minimum_size = size
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _make_button(text: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	b.size = size
	b.modulate = Color(1, 1, 1, 0.85)
	return b


func update_ability_labels() -> void:
	var abilities: Array = GameManager.get_class_abilities()
	for i in range(ability_buttons.size()):
		if i < abilities.size():
			ability_buttons[i].text = abilities[i]["name"]
			ability_buttons[i].disabled = false
		else:
			ability_buttons[i].text = "-"
			ability_buttons[i].disabled = true


func _process(_delta: float) -> void:
	update_ability_labels()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start(event.index, event.position)
		else:
			_touch_end(event.index)
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position, event.relative)


func _touch_over_button(pos: Vector2) -> bool:
	for b in buttons:
		if is_instance_valid(b) and b.get_global_rect().has_point(pos):
			return true
	return false


func _touch_start(index: int, pos: Vector2) -> void:
	if _touch_over_button(pos):
		return
	var vp_size := get_viewport().get_visible_rect().size
	if pos.x < vp_size.x * 0.5:
		if joystick_touch_index == -1:
			joystick_touch_index = index
			joystick_center = pos
			joystick_base.visible = true
			joystick_knob.visible = true
			joystick_base.global_position = pos - joystick_base.size * 0.5
			joystick_knob.global_position = pos - joystick_knob.size * 0.5
	else:
		if camera_touch_index == -1:
			camera_touch_index = index


func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if index == joystick_touch_index:
		var offset := pos - joystick_center
		var clamped := offset.limit_length(JOYSTICK_RADIUS)
		joystick_knob.global_position = joystick_center + clamped - joystick_knob.size * 0.5
		InputState.move_vector = clamped / JOYSTICK_RADIUS
	elif index == camera_touch_index:
		InputState.look_delta += relative


func _touch_end(index: int) -> void:
	if index == joystick_touch_index:
		joystick_touch_index = -1
		joystick_base.visible = false
		joystick_knob.visible = false
		InputState.move_vector = Vector2.ZERO
	elif index == camera_touch_index:
		camera_touch_index = -1
