extends Area2D

@export var dialogue_id: String = ""
@export var next_scene: String = ""
@export var one_shot: bool = true

var _triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered and one_shot:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true

	if not dialogue_id.is_empty():
		if DialogueManager.has_dialogue(dialogue_id):
			if not next_scene.is_empty():
				DialogueManager.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
			DialogueManager.start_dialogue(dialogue_id)
		else:
			push_warning("EventTrigger: unknown dialogue id '%s'" % dialogue_id)
			if not next_scene.is_empty():
				SceneManager.change_scene(next_scene)
	elif not next_scene.is_empty():
		SceneManager.change_scene(next_scene)

	if one_shot:
		monitoring = false

func _on_dialogue_finished() -> void:
	if not next_scene.is_empty():
		SceneManager.change_scene(next_scene)
