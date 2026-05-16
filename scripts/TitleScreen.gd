extends Node2D

@onready var _prompt: Label = $UI/PressSpaceLabel
@onready var _bg: Sprite2D = $Background

func _ready() -> void:
	AudioManager.play_music("res://assets/audio/music/titlescreen.wav")
	_blink_prompt()

func _blink_prompt() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_prompt, "modulate:a", 0.0, 0.6)
	tween.tween_property(_prompt, "modulate:a", 1.0, 0.6)

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_accept") or event.is_action_just_pressed("dash"):
		SceneManager.change_scene("res://scenes/levels/Level01.tscn")
