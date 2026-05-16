extends Node

const FADE_TIME := 1.0

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	add_child(_sfx)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

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
