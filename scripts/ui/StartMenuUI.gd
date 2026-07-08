extends CanvasLayer
class_name StartMenuUI

signal new_game_pressed()
signal continue_pressed()

var continue_btn: Button


func _ready() -> void:
	layer = 20
	var bg := TextureRect.new()
	bg.texture = GameTheme.background_texture(Color(0.09, 0.12, 0.09, 1), Color(0.05, 0.04, 0.03, 1))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)

	var title := Label.new()
	title.text = "NORDMARK LEGENDS"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-320, 70)
	title.size = Vector2(640, 64)
	bg.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ein eigenständiges Mittelalter-Rollenspiel — Königreich Eichenmark"
	subtitle.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-260, 132)
	subtitle.size = Vector2(520, 50)
	bg.add_child(subtitle)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(320, 200)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-160, -100)
	bg.add_child(panel)

	var new_btn := Button.new()
	new_btn.text = "Neues Spiel"
	new_btn.theme_type_variation = "PrimaryButton"
	new_btn.custom_minimum_size = Vector2(272, 64)
	new_btn.position = Vector2(24, 24)
	new_btn.pressed.connect(func(): new_game_pressed.emit())
	panel.add_child(new_btn)

	continue_btn = Button.new()
	continue_btn.text = "Weiter spielen"
	continue_btn.custom_minimum_size = Vector2(272, 64)
	continue_btn.position = Vector2(24, 104)
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	panel.add_child(continue_btn)

	var footer := Label.new()
	footer.text = "Offline · Keine Internetverbindung nötig"
	footer.add_theme_font_size_override("font_size", 15)
	footer.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer.position = Vector2(-160, -40)
	footer.size = Vector2(320, 30)
	bg.add_child(footer)


func set_continue_enabled(enabled: bool) -> void:
	continue_btn.disabled = not enabled
