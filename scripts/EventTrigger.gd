extends Area2D

@export var dialogue_id: String = ""
@export var one_shot: bool = true

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered and one_shot:
		return
	if not body.is_in_group("player"):
		return
	if dialogue_id.is_empty():
		return
	_triggered = true
	DialogueManager.start_dialogue(dialogue_id)
	if one_shot:
		monitoring = false
