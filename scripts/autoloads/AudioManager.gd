extends Node

const FADE_TIME := 1.0
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = _resolve_bus(MUSIC_BUS)
	add_child(_music)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = _resolve_bus(SFX_BUS)
	add_child(_sfx)

func _exit_tree() -> void:
	if _music != null:
		_music.stop()
		_music.stream = null
	if _sfx != null:
		_sfx.stop()
		_sfx.stream = null

func _resolve_bus(bus_name: String) -> StringName:
	if AudioServer.get_bus_index(bus_name) == -1:
		return &"Master"
	return StringName(bus_name)

func play_music(path: String, volume_db: float = 0.0) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("AudioManager: could not load music '%s'" % path)
		return
	_music.stream = stream
	_music.volume_db = volume_db
	_music.play()

func stop_music() -> void:
	if _music == null or not _music.playing:
		return
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", -80.0, FADE_TIME)
	tween.tween_callback(_music.stop)

func play_sfx(path: String) -> void:
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_sfx.stream = stream
	_sfx.play()
