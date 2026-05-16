extends CanvasLayer

signal scene_changed(scene_path: String)

const FADE_DURATION := 0.4

var _overlay: ColorRect
var _target_scene: String = ""
var _fading: bool = false

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func change_scene(path: String) -> void:
	if _fading:
		return
	_fading = true
	_target_scene = path
	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 1), FADE_DURATION)
	tween.tween_callback(_do_scene_change)

func _do_scene_change() -> void:
	get_tree().change_scene_to_file(_target_scene)
	scene_changed.emit(_target_scene)
	_target_scene = ""
	var tween := create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 0), FADE_DURATION)
	tween.tween_callback(func(): _fading = false)
