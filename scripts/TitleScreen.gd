extends Node2D

@onready var _prompt: Label = $UI/PressSpaceLabel

func _ready() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_prompt, "modulate:a", 0.0, 0.6)
	tween.tween_property(_prompt, "modulate:a", 1.0, 0.6)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_accept"):
		SceneManager.change_scene("res://scenes/levels/Level01.tscn")
