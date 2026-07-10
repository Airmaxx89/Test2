extends Label
class_name DamageNumber
## Aufsteigende Schadenszahl (2D-Overlay im HUD).
## Selbstzerstoerend nach der Animation. Farbe je nach Kontext.

func show_number(amount: int, is_crit: bool, to_player: bool) -> void:
	text = str(amount)
	var color := Color.WHITE
	if to_player:
		color = Color(1.0, 0.35, 0.3)      # Schaden am Spieler -> rot
	elif is_crit:
		color = Color(1.0, 0.85, 0.1)      # Krit -> gold
		text += "!"
	else:
		color = Color(1.0, 0.95, 0.85)     # normaler Schaden -> hell
	add_theme_color_override("font_color", color)
	add_theme_font_size_override("font_size", 28 if is_crit else 20)

	# Nach oben schweben + ausblenden, dann freigeben.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60.0, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
