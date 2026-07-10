extends CanvasLayer
class_name StartMenuUI

signal new_game_pressed()
signal continue_pressed()

var continue_btn: Button
var confirm_panel: Panel
var has_save: bool = false


func _ready() -> void:
	layer = 20

	var campfire := CampfireBackground.new()
	add_child(campfire)

	var overlay := TextureRect.new()
	overlay.texture = GameTheme.background_texture(Color(0.03, 0.02, 0.02, 0.25), Color(0.02, 0.01, 0.01, 0.75))
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var content := Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	var title := Label.new()
	title.text = "NORDMARK LEGENDS"
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-320, 70)
	title.size = Vector2(640, 64)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ein eigenständiges Mittelalter-Rollenspiel — Königreich Eichenmark"
	subtitle.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-260, 132)
	subtitle.size = Vector2(520, 50)
	content.add_child(subtitle)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(320, 200)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-160, -100)
	content.add_child(panel)

	var new_btn := Button.new()
	new_btn.text = "Neues Spiel"
	new_btn.theme_type_variation = "PrimaryButton"
	new_btn.custom_minimum_size = Vector2(272, 64)
	new_btn.position = Vector2(24, 24)
	new_btn.pressed.connect(_on_new_game_pressed)
	new_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(new_btn)

	continue_btn = Button.new()
	continue_btn.text = "Weiter spielen"
	continue_btn.custom_minimum_size = Vector2(272, 64)
	continue_btn.position = Vector2(24, 104)
	continue_btn.pressed.connect(func(): continue_pressed.emit())
	continue_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(continue_btn)

	var footer := Label.new()
	footer.text = "Offline · Keine Internetverbindung nötig"
	footer.add_theme_font_size_override("font_size", 15)
	footer.add_theme_color_override("font_color", GameTheme.TEXT_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer.position = Vector2(-160, -40)
	footer.size = Vector2(320, 30)
	content.add_child(footer)

	_build_confirm_dialog(content)


func _build_confirm_dialog(content: Control) -> void:
	confirm_panel = Panel.new()
	confirm_panel.custom_minimum_size = Vector2(420, 220)
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.position = Vector2(-210, -110)
	confirm_panel.visible = false
	content.add_child(confirm_panel)

	var msg := Label.new()
	msg.text = "Ein Spielstand existiert bereits.\nWirklich ein neues Spiel starten?\nDer bisherige Fortschritt geht verloren."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.position = Vector2(20, 20)
	msg.size = Vector2(380, 100)
	confirm_panel.add_child(msg)

	var cancel_btn := Button.new()
	cancel_btn.text = "Abbrechen"
	cancel_btn.custom_minimum_size = Vector2(180, 56)
	cancel_btn.position = Vector2(20, 140)
	cancel_btn.pressed.connect(func(): confirm_panel.visible = false)
	confirm_panel.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Ja, neues Spiel"
	confirm_btn.theme_type_variation = "PrimaryButton"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.position = Vector2(220, 140)
	confirm_btn.pressed.connect(func():
		confirm_panel.visible = false
		new_game_pressed.emit()
	)
	confirm_panel.add_child(confirm_btn)


func _on_new_game_pressed() -> void:
	if has_save:
		confirm_panel.visible = true
	else:
		new_game_pressed.emit()


func set_continue_enabled(enabled: bool) -> void:
	has_save = enabled
	continue_btn.disabled = not enabled
