extends CanvasLayer

signal dialogue_started(dialogue_id: String)
signal dialogue_finished

const TYPEWRITER_SPEED := 40.0

# Map short portrait names (used in JSON) to file paths
const PORTRAIT_MAP := {
	"Elizabeth":         "res://assets/sprites/Dialog_UI/Elizabeth.png",
	"Happy":             "res://assets/sprites/Dialog_UI/Happy.png",
	"Ouch":              "res://assets/sprites/Dialog_UI/Ouch.png",
	"Shocked":           "res://assets/sprites/Dialog_UI/Shocked.png",
	"Sleepy":            "res://assets/sprites/Dialog_UI/Sleepy.png",
	"Tears":             "res://assets/sprites/Dialog_UI/Tears.png",
	"Tired":             "res://assets/sprites/Dialog_UI/Tired.png",
	"tmp_Crying":        "res://assets/sprites/Dialog_UI/tmp_Crying.png",
	"tmp_yell":          "res://assets/sprites/Dialog_UI/tmp_yell.png",
	"AdditionalElizabeth": "res://assets/sprites/Dialog_UI/AdditionalElizabeth.png",
}

var _dialogue_data: Dictionary = {}
var _lines: Array = []
var _current_index: int = 0
var _active: bool = false
var _typing: bool = false
var _full_text: String = ""

# UI nodes (created programmatically so no .tscn dependency)
var _panel: Panel
var _portrait: TextureRect
var _name_label: Label
var _text_label: RichTextLabel
var _continue_btn: Button

func _ready() -> void:
	layer = 50
	_build_ui()
	_load_all_dialogue()

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.anchor_left = 0.04
	_panel.anchor_top = 0.10
	_panel.anchor_right = 0.96
	_panel.anchor_bottom = 0.56
	_panel.hide()
	add_child(_panel)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	hbox.add_theme_constant_override("separation", 12)
	_panel.add_child(hbox)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(80, 80)
	_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(_portrait)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_name_label)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.fit_content = false
	_text_label.scroll_active = false
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_text_label)

	_continue_btn = Button.new()
	_continue_btn.text = "Continue."
	_continue_btn.anchor_left = 0.3
	_continue_btn.anchor_top = 0.56
	_continue_btn.anchor_right = 0.7
	_continue_btn.anchor_bottom = 0.65
	_continue_btn.hide()
	_continue_btn.pressed.connect(_on_continue_pressed)
	add_child(_continue_btn)

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_just_pressed("ui_accept") or event.is_action_just_pressed("dash"):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()

func _load_all_dialogue() -> void:
	var dir := DirAccess.open("res://data/dialogue/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			_load_file("res://data/dialogue/" + file_name)
		file_name = dir.get_next()

func _load_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_dialogue_data.merge(parsed)

func start_dialogue(dialogue_id: String) -> void:
	if not _dialogue_data.has(dialogue_id):
		push_warning("DialogueManager: unknown id '%s'" % dialogue_id)
		return
	_lines = _dialogue_data[dialogue_id].get("lines", [])
	_current_index = 0
	_active = true
	_panel.show()
	_continue_btn.hide()
	dialogue_started.emit(dialogue_id)
	_show_current_line()

func advance() -> void:
	if not _active:
		return
	_current_index += 1
	if _current_index >= _lines.size():
		_end_dialogue()
	else:
		_show_current_line()

func _show_current_line() -> void:
	var line: Dictionary = _lines[_current_index]
	_name_label.text = line.get("speaker", "")

	var portrait_key: String = line.get("portrait", "")
	var portrait_path: String = PORTRAIT_MAP.get(portrait_key, portrait_key)
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_portrait.texture = load(portrait_path)
		_portrait.show()
	else:
		_portrait.hide()

	_full_text = line.get("text", "")
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_typing = true
	_continue_btn.hide()

	var tween := create_tween()
	tween.tween_property(_text_label, "visible_characters", len(_full_text), len(_full_text) / TYPEWRITER_SPEED)
	tween.tween_callback(_finish_typing)

func _finish_typing() -> void:
	_typing = false
	_continue_btn.show()

func _on_continue_pressed() -> void:
	if _typing:
		_text_label.visible_characters = len(_full_text)
		_typing = false
		_continue_btn.show()
		return
	advance()

func _end_dialogue() -> void:
	_active = false
	_panel.hide()
	_continue_btn.hide()
	_lines.clear()
	dialogue_finished.emit()

func is_active() -> bool:
	return _active
