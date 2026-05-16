extends SceneTree

const SCENES := [
	"res://scenes/TitleScreen.tscn",
	"res://scenes/levels/Level01.tscn",
	"res://scenes/levels/Level02.tscn",
]

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("RuntimeSmokeTest: starting")

	for scene_path in SCENES:
		await _load_scene(scene_path)

	if root.has_node("/root/AudioManager"):
		root.get_node("/root/AudioManager").stop_music()
		await create_timer(1.1).timeout

	print("RuntimeSmokeTest: finished with %d failure(s)" % _failures)
	quit(_failures)

func _load_scene(scene_path: String) -> void:
	print("RuntimeSmokeTest: loading ", scene_path)

	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("RuntimeSmokeTest: failed to load " + scene_path)
		_failures += 1
		return

	var scene := packed.instantiate()
	if scene == null:
		push_error("RuntimeSmokeTest: failed to instantiate " + scene_path)
		_failures += 1
		return

	root.add_child(scene)

	for i in range(8):
		await process_frame

	scene.queue_free()
	await process_frame
