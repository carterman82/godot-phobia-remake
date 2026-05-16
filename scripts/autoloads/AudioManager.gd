extends Node

const FADE_TIME := 1.0

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	add_child(_sfx)

func play_music(path: String, volume_db: float = 0.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: could not load music '%s'" % path)
		return
	_music.stream = stream
	_music.volume_db = volume_db
	_music.play()

func stop_music() -> void:
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", -80.0, FADE_TIME)
	tween.tween_callback(_music.stop)

func play_sfx(path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.play()
