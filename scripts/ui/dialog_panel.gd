extends Control
class_name DialogPanel
## Dialog- & Quest-Angebots-Panel.
## Zwei Modi:
##  - Einfacher Dialog (show_dialog Event): NPC-Zeilen anzeigen + Weiter/Schliessen.
##  - Quest-Angebot (quest_offered Event): Zusammenfassung + Annehmen/Ablehnen.

@onready var _name_label: Label = $Panel/VBox/NpcName
@onready var _body: RichTextLabel = $Panel/VBox/Body
@onready var _accept_btn: Button = $Panel/VBox/Buttons/AcceptButton
@onready var _decline_btn: Button = $Panel/VBox/Buttons/DeclineButton

var _pending_quest: QuestData

func _ready() -> void:
	visible = false
	_accept_btn.pressed.connect(_on_accept)
	_decline_btn.pressed.connect(hide_panel)
	Events.show_dialog.connect(_on_show_dialog)
	Events.quest_offered.connect(_on_quest_offered)

func _on_show_dialog(npc_name: String, lines: Array) -> void:
	_pending_quest = null
	_name_label.text = npc_name
	_body.text = "\n".join(PackedStringArray(lines))
	_accept_btn.visible = false
	_decline_btn.text = "Schliessen"
	visible = true
	get_tree().paused = true

func _on_quest_offered(q: QuestData) -> void:
	_pending_quest = q
	_name_label.text = q.title
	var text := q.summary + "\n\n[b]Ziele:[/b]\n"
	for obj in q.objectives:
		text += "- %s (%d)\n" % [obj["label"], int(obj["amount"])]
	text += "\n[b]Belohnung:[/b] %d XP, %d Gold" % [q.reward_xp, q.reward_gold]
	_body.text = text
	_accept_btn.visible = true
	_accept_btn.text = "Annehmen"
	_decline_btn.text = "Ablehnen"
	visible = true
	get_tree().paused = true

func _on_accept() -> void:
	if _pending_quest:
		QuestTracker.accept_quest(_pending_quest.id)
	hide_panel()

func hide_panel() -> void:
	visible = false
	_pending_quest = null
	get_tree().paused = false
