extends Control
class_name MainMenu
## Hauptmenue: Neues Spiel / Fortsetzen / Beenden.
## Wird von main.gd gesteuert. Signalisiert die Auswahl nach oben.

signal new_game_requested()
signal continue_requested()

@onready var _continue_btn: Button = $CenterContainer/VBox/ContinueButton

func _ready() -> void:
	$CenterContainer/VBox/NewGameButton.pressed.connect(func(): new_game_requested.emit())
	_continue_btn.pressed.connect(func(): continue_requested.emit())
	$CenterContainer/VBox/QuitButton.pressed.connect(_on_quit)
	# "Fortsetzen" nur aktiv, wenn ein Save existiert.
	_continue_btn.disabled = not SaveManager.has_save()

func _on_quit() -> void:
	get_tree().quit()
