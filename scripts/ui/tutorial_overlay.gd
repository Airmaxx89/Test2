extends Control
class_name TutorialOverlay
## Einmalige On-Screen-Tutorials fuer Mobile-Controls.
## Zeigt nacheinander Hinweise zu Joystick, Kamera, Skills, Interaktion.
## Speichert den "gesehen"-Status lokal (user://tutorial.cfg), damit es nur
## beim ersten Start erscheint.

const CFG_PATH := "user://tutorial.cfg"

var _steps := [
	"Bewege dich mit dem virtuellen JOYSTICK (linke Bildschirmhaelfte).",
	"Drehe die KAMERA durch Wischen auf der rechten Bildschirmhaelfte. Zwei Finger = Zoom.",
	"Tippe die SKILL-Buttons unten rechts, um Faehigkeiten einzusetzen. Auto-Angriff laeuft automatisch.",
	"Naehere dich NPCs mit '!' und tippe INTERAGIEREN, um Quests anzunehmen.",
	"Oeffne JOURNAL und INVENTAR ueber die Buttons oben rechts. Viel Erfolg!",
]
var _index := 0

@onready var _label: Label = $Center/Panel/VBox/Text
@onready var _next_btn: Button = $Center/Panel/VBox/NextButton

func _ready() -> void:
	if _already_seen():
		queue_free()
		return
	_next_btn.pressed.connect(_advance)
	_show_step()

func _show_step() -> void:
	_label.text = "(%d/%d)\n\n%s" % [_index + 1, _steps.size(), _steps[_index]]
	_next_btn.text = "Weiter" if _index < _steps.size() - 1 else "Los geht's!"

func _advance() -> void:
	_index += 1
	if _index >= _steps.size():
		_mark_seen()
		queue_free()
	else:
		_show_step()

func _already_seen() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) == OK:
		return cfg.get_value("tutorial", "seen", false)
	return false

func _mark_seen() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("tutorial", "seen", true)
	cfg.save(CFG_PATH)
