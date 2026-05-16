extends CharacterBody2D

const SPEED := 120.0
const GRAVITY := 600.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func _physics_process(delta: float) -> void:
	if DialogueManager.is_active():
		velocity.x = 0
		_play_animation("idle")
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	if direction != 0:
		_sprite.flip_h = direction < 0
		_play_animation("walk")
	else:
		_play_animation("idle")

	move_and_slide()

func _play_animation(anim: String) -> void:
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim):
		if _sprite.animation != anim:
			_sprite.play(anim)

func _on_dialogue_started(_id: String) -> void:
	velocity = Vector2.ZERO

func _on_dialogue_finished() -> void:
	pass
