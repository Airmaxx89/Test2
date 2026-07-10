extends CanvasLayer
class_name PauseMenuUI
## In-game pause/settings overlay - opened via the Android back button or a
## HUD button (see Main._unhandled_input/_notification). Lets the player
## save on demand, adjust SFX/music volume, and return to the main menu
## with a confirmation step (mirrors StartMenuUI's confirm-dialog pattern).

signal quit_to_menu_confirmed()

var panel: Panel
var confirm_panel: Panel
var save_label: Label
var save_tween: Tween
var is_open: bool = false


func _ready() -> void:
	layer = 15
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(420, 420)
	panel.size = Vector2(420, 420)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-210, -210)
	panel.visible = false
	add_child(panel)

	var title := Label.new()
	title.text = "Pause"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GameTheme.ACCENT_BRIGHT)
	title.position = Vector2(20, 16)
	panel.add_child(title)

	var resume_btn := Button.new()
	resume_btn.text = "Fortsetzen"
	resume_btn.theme_type_variation = "PrimaryButton"
	resume_btn.custom_minimum_size = Vector2(380, 56)
	resume_btn.position = Vector2(20, 66)
	resume_btn.pressed.connect(close)
	resume_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(resume_btn)

	var save_btn := Button.new()
	save_btn.text = "Speichern"
	save_btn.custom_minimum_size = Vector2(380, 56)
	save_btn.position = Vector2(20, 132)
	save_btn.pressed.connect(_on_save_pressed)
	panel.add_child(save_btn)

	save_label = Label.new()
	save_label.text = ""
	save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_label.add_theme_color_override("font_color", GameTheme.XP_COLOR)
	save_label.position = Vector2(20, 192)
	save_label.size = Vector2(380, 24)
	panel.add_child(save_label)

	var sfx_label := Label.new()
	sfx_label.text = "Effekte"
	sfx_label.add_theme_font_size_override("font_size", 16)
	sfx_label.position = Vector2(20, 232)
	panel.add_child(sfx_label)

	var sfx_slider := HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = AudioManager.get_sfx_volume()
	sfx_slider.position = Vector2(20, 262)
	sfx_slider.size = Vector2(380, 24)
	sfx_slider.value_changed.connect(func(v): AudioManager.set_sfx_volume(v))
	panel.add_child(sfx_slider)

	var music_label := Label.new()
	music_label.text = "Musik & Ambiente"
	music_label.add_theme_font_size_override("font_size", 16)
	music_label.position = Vector2(20, 296)
	panel.add_child(music_label)

	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.05
	music_slider.value = AudioManager.get_music_volume()
	music_slider.position = Vector2(20, 326)
	music_slider.size = Vector2(380, 24)
	music_slider.value_changed.connect(func(v): AudioManager.set_music_volume(v))
	panel.add_child(music_slider)

	var quit_btn := Button.new()
	quit_btn.text = "Zum Hauptmenü"
	quit_btn.custom_minimum_size = Vector2(380, 56)
	quit_btn.position = Vector2(20, 356)
	quit_btn.pressed.connect(func(): confirm_panel.visible = true)
	quit_btn.pressed.connect(func(): AudioManager.play_sfx("button_click"))
	panel.add_child(quit_btn)

	_build_confirm_dialog()


func _build_confirm_dialog() -> void:
	confirm_panel = Panel.new()
	confirm_panel.custom_minimum_size = Vector2(420, 200)
	confirm_panel.set_anchors_preset(Control.PRESET_CENTER)
	confirm_panel.position = Vector2(-210, -100)
	confirm_panel.visible = false
	add_child(confirm_panel)

	var msg := Label.new()
	msg.text = "Zum Hauptmenü zurückkehren?\nDer Fortschritt wird vorher gespeichert."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.position = Vector2(20, 20)
	msg.size = Vector2(380, 80)
	confirm_panel.add_child(msg)

	var cancel_btn := Button.new()
	cancel_btn.text = "Abbrechen"
	cancel_btn.custom_minimum_size = Vector2(180, 56)
	cancel_btn.position = Vector2(20, 120)
	cancel_btn.pressed.connect(func(): confirm_panel.visible = false)
	confirm_panel.add_child(cancel_btn)

	var confirm_btn := Button.new()
	confirm_btn.text = "Ja, verlassen"
	confirm_btn.theme_type_variation = "PrimaryButton"
	confirm_btn.custom_minimum_size = Vector2(180, 56)
	confirm_btn.position = Vector2(220, 120)
	confirm_btn.pressed.connect(func():
		confirm_panel.visible = false
		SaveManager.save_game()
		quit_to_menu_confirmed.emit()
	)
	confirm_panel.add_child(confirm_btn)


func _on_save_pressed() -> void:
	SaveManager.save_game()
	AudioManager.play_sfx("button_click")
	save_label.text = "Gespeichert!"
	if save_tween:
		save_tween.kill()
	save_tween = create_tween()
	save_tween.tween_interval(1.5)
	save_tween.tween_callback(func(): save_label.text = "")


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	panel.visible = true


func close() -> void:
	is_open = false
	panel.visible = false
	confirm_panel.visible = false
