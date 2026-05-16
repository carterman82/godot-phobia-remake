extends Node

const SCENES := [
	"res://scenes/TitleScreen.tscn",
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
]

const DIALOGUES := [
	"intro_01",
	"street_lamp_01",
	"nyctophobia_trigger",
	"claustrophobia_enter",
	"anthropophobia_enter",
	"finale_realization",
]

var _failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	print("RuntimeSmokeTest: starting")

	await _load_all_scenes()
	await _exercise_title_input()
	await _exercise_dialogues()
	await _exercise_player_and_triggers()
	await _stop_audio()

	print("RuntimeSmokeTest: finished with %d failure(s)" % _failures)
	get_tree().quit(_failures)

func _load_all_scenes() -> void:
	for scene_path in SCENES:
		await _load_scene(scene_path)

func _load_scene(scene_path: String) -> void:
	print("RuntimeSmokeTest: loading ", scene_path)

	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("failed to load " + scene_path)
		return

	var scene := packed.instantiate()
	if scene == null:
		_fail("failed to instantiate " + scene_path)
		return

	add_child(scene)
	await _pump_frames(8)
	scene.queue_free()
	await get_tree().process_frame

func _exercise_title_input() -> void:
	print("RuntimeSmokeTest: exercising title input")
	var scene := _instantiate("res://scenes/TitleScreen.tscn")
	if scene == null:
		return

	var mouse_motion := InputEventMouseMotion.new()
	scene._input(mouse_motion)
	await get_tree().process_frame

	remove_child(scene)
	scene.queue_free()
	await get_tree().process_frame

func _exercise_dialogues() -> void:
	print("RuntimeSmokeTest: exercising dialogue flow")
	var mouse_motion := InputEventMouseMotion.new()
	for dialogue_id in DIALOGUES:
		if not DialogueManager.has_dialogue(dialogue_id):
			_fail("missing dialogue id " + dialogue_id)
			continue

		DialogueManager.start_dialogue(dialogue_id)
		DialogueManager._input(mouse_motion)
		var guard := 0
		while DialogueManager.is_active() and guard < 64:
			DialogueManager.advance()
			await get_tree().process_frame
			guard += 1
		if DialogueManager.is_active():
			_fail("dialogue did not finish: " + dialogue_id)

func _exercise_player_and_triggers() -> void:
	print("RuntimeSmokeTest: exercising Level01 gameplay nodes")
	var level := _instantiate("res://scenes/levels/Level01.tscn")
	if level == null:
		return

	await _pump_frames(16)

	var player := level.get_node_or_null("Player")
	if player == null:
		_fail("Level01 missing Player")
	else:
		Input.action_press("move_right")
		await _pump_frames(12)
		Input.action_release("move_right")
		Input.action_press("jump")
		await _pump_frames(2)
		Input.action_release("jump")
		await _pump_frames(12)
		Input.action_press("dash")
		await _pump_frames(4)
		Input.action_release("dash")
		await _pump_frames(12)

	var intro := level.get_node_or_null("IntroTrigger")
	if intro != null and player != null:
		intro._on_body_entered(player)
		await _clear_active_dialogue()
	else:
		_fail("Level01 missing IntroTrigger or Player")

	if level.get_node_or_null("LevelExit") == null:
		_fail("Level01 missing LevelExit")

	if is_instance_valid(level) and level.get_parent() == self:
		remove_child(level)
		level.queue_free()
	await get_tree().process_frame

func _clear_active_dialogue() -> void:
	var guard := 0
	while DialogueManager.is_active() and guard < 64:
		DialogueManager.advance()
		await get_tree().process_frame
		guard += 1
	if DialogueManager.is_active():
		_fail("active dialogue could not be cleared")

func _instantiate(scene_path: String) -> Node:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("failed to load " + scene_path)
		return null
	var scene := packed.instantiate()
	if scene == null:
		_fail("failed to instantiate " + scene_path)
		return null
	add_child(scene)
	return scene

func _pump_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _stop_audio() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").stop_music()
		await get_tree().create_timer(1.1).timeout

func _fail(message: String) -> void:
	_failures += 1
	push_error("RuntimeSmokeTest: " + message)
