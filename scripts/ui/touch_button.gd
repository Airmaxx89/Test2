extends Button
class_name TouchButton
## Multi-Touch-freundlicher Aktionsbutton (Skill/Sprint/Jump/Interact).
## Basiert auf Button -> sofort sichtbar & druckbar OHNE Textur-Assets
## (spaeter kann per set_icon_texture ein Icon gesetzt werden).
## Ein optionales ColorRect-Kind "Cooldown" visualisiert die Abklingzeit als
## abdunkelndes Overlay. Mehrere Buttons sind gleichzeitig druckbar (Touch).

signal activated(button_id: StringName)

@export var button_id: StringName = &"skill_0"
@export var label_text: String = ""

@onready var _cooldown_overlay: ColorRect = get_node_or_null("Cooldown")

func _ready() -> void:
	# Touch/Klick: sofort bei Druck ausloesen -> responsiver auf Mobile.
	button_down.connect(_on_pressed)
	if label_text != "":
		text = label_text
	if _cooldown_overlay:
		_cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cooldown_overlay.visible = false

func _on_pressed() -> void:
	activated.emit(button_id)

## Cooldown-Ratio 0..1 (1 = gerade ausgeloest, 0 = bereit).
func set_cooldown(ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	if _cooldown_overlay:
		_cooldown_overlay.visible = ratio > 0.001
		_cooldown_overlay.color = Color(0, 0, 0, 0.6 * ratio)

func set_label(t: String) -> void:
	text = t

func set_icon_texture(tex: Texture2D) -> void:
	if tex:
		icon = tex
