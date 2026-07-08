extends CanvasLayer
class_name StartMenuUI

signal new_game_pressed()
signal continue_pressed()

var continue_btn: Button


func _ready() -> void:
	layer = 20
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.08, 0.06, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Nordmark Legends"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-220, 160)
	title.size = Vector2(440, 60)
	bg.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ein eigenständiges Mittelalter-Rollenspiel\nStartgebiet: Königreich Eichenmark"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-220, 230)
	subtitle.size = Vector2(440, 80)
	bg.add_child(subtitle)

	var new_btn := Button.new()
	new_btn.text = "Neues Spiel"
	new_btn.custom_minimum_size = Vector2(260, 70)
	new_btn.set_anchors_preset(Control.PRESET_CENTER)
	new_btn.position = Vector2(-130, -40)
	new_btn.pressed.connect(func(): new_game_pressed.emit())
	bg.add_child(new_btn)

	continue_btn = Button.new()
	continue_btn.text = "Weiter spielen"
	continue_btn.custom_minimum_size = Vector2(260, 70)
	continue_btn.set_anchors_preset(Control.PRESET_CENTER)
	continue_btn.position = Vector2(-130, 50)
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	bg.add_child(continue_btn)


func set_continue_enabled(enabled: bool) -> void:
	continue_btn.disabled = not enabled
