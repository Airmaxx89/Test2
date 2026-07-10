extends Control
class_name CharacterCreation
## Charakter-Erstellung: Name, Klassenwahl (Warrior/Mage) und Grund-Optik (Farbe).
## Baut die Klassen-Buttons dynamisch aus der Database.

signal created(char_name: String, class_id: StringName)
signal cancelled()

@onready var _name_edit: LineEdit = $Panel/VBox/NameEdit
@onready var _class_container: HBoxContainer = $Panel/VBox/ClassContainer
@onready var _desc_label: Label = $Panel/VBox/DescLabel
@onready var _preview: ColorRect = $Panel/VBox/Preview
@onready var _confirm_btn: Button = $Panel/VBox/ConfirmButton

var _selected_class: StringName = &"warrior"
var _class_buttons: Dictionary = {}

func _ready() -> void:
	_name_edit.text = "Held"
	_build_class_buttons()
	_confirm_btn.pressed.connect(_on_confirm)
	$Panel/VBox/CancelButton.pressed.connect(func(): cancelled.emit())
	_select_class(&"warrior")

func _build_class_buttons() -> void:
	for id in Database.classes:
		var cls: ClassData = Database.classes[id]
		var btn := Button.new()
		btn.text = cls.display_name
		btn.custom_minimum_size = Vector2(140, 64)
		btn.toggle_mode = true
		btn.pressed.connect(_select_class.bind(id))
		_class_container.add_child(btn)
		_class_buttons[id] = btn

func _select_class(id: StringName) -> void:
	_selected_class = id
	var cls: ClassData = Database.get_char_class(id)
	if cls:
		_desc_label.text = cls.description
		_preview.color = cls.body_color
	for cid in _class_buttons:
		(_class_buttons[cid] as Button).button_pressed = (cid == id)

func _on_confirm() -> void:
	var nm := _name_edit.text.strip_edges()
	if nm.is_empty():
		nm = "Held"
	created.emit(nm, _selected_class)
