extends Node2D

@export var music_path: String = ""

func _ready() -> void:
	if music_path != "":
		AudioManager.play_music(music_path)
