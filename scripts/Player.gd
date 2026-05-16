extends CharacterBody2D

# Movement
const SPEED := 150.0
const GRAVITY := 900.0
const MAX_FALL_SPEED := 600.0

# Jump
const JUMP_VELOCITY := -340.0
const MAX_JUMPS := 2
const JUMP_RELEASE_MULT := 0.45  # vertical velocity multiplier on early jump release

# Coyote time & jump buffer
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.1

# Dash
const DASH_SPEED := 420.0
const DASH_DURATION := 0.18        # minimum dash duration (tap)
const DASH_MAX_DURATION := 0.35    # maximum dash duration (hold)
const DASH_COOLDOWN := 0.8

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _jumps_left := MAX_JUMPS
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown := 0.0
var _dash_dir := 1          # 1 = right, -1 = left
var _can_dash := true

func _ready() -> void:
	add_to_group("player")
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

func _physics_process(delta: float) -> void:
	if DialogueManager.is_active():
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		_apply_gravity(delta)
		_play_anim("idle")
		move_and_slide()
		return

	var on_floor := is_on_floor()

	# Landing
	if on_floor and not _was_on_floor:
		AudioManager.play_sfx("res://assets/audio/sfx/land.wav")
		_jumps_left = MAX_JUMPS
		_can_dash = true

	# Coyote timer
	if on_floor:
		_coyote_timer = COYOTE_TIME
		_jumps_left = MAX_JUMPS
	else:
		_coyote_timer -= delta

	_was_on_floor = on_floor

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta

	# Dash cooldown
	_dash_cooldown -= delta

	# Start dash
	if Input.is_action_just_pressed("dash") and _can_dash and _dash_cooldown <= 0:
		_start_dash()

	# Dashing overrides normal movement
	if _is_dashing:
		_process_dash(delta)
		move_and_slide()
		return

	# Gravity
	_apply_gravity(delta)

	# Variable jump: releasing jump early cuts upward velocity
	if velocity.y < 0 and not Input.is_action_pressed("jump"):
		velocity.y *= pow(JUMP_RELEASE_MULT, delta * 60.0)

	# Execute buffered jump
	if _jump_buffer_timer > 0:
		var can_ground_jump := _coyote_timer > 0 and _jumps_left == MAX_JUMPS
		if can_ground_jump:
			_do_jump(false)
		elif _jumps_left > 0 and not on_floor:
			_do_jump(true)

	# Horizontal movement
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED

	if dir != 0:
		_dash_dir = int(sign(dir))
		_sprite.flip_h = dir < 0
		_play_anim("walk")
	else:
		_play_anim("idle")

	move_and_slide()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

func _do_jump(is_double: bool) -> void:
	velocity.y = JUMP_VELOCITY
	_jumps_left -= 1
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	if is_double:
		AudioManager.play_sfx("res://assets/audio/sfx/jump.wav")
	else:
		AudioManager.play_sfx("res://assets/audio/sfx/realjump.wav")

func _start_dash() -> void:
	_is_dashing = true
	_dash_timer = 0.0
	_can_dash = false
	_dash_cooldown = DASH_COOLDOWN
	velocity.y = 0.0
	AudioManager.play_sfx("res://assets/audio/sfx/please rename this.mp3")

func _process_dash(delta: float) -> void:
	_dash_timer += delta
	var max_dur := DASH_MAX_DURATION if Input.is_action_pressed("dash") else DASH_DURATION
	if _dash_timer >= max_dur:
		_is_dashing = false
		velocity.x = _dash_dir * SPEED
		return
	velocity.x = _dash_dir * DASH_SPEED
	velocity.y = 0.0

func _play_anim(anim: String) -> void:
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim):
		if _sprite.animation != anim:
			_sprite.play(anim)

func _on_dialogue_started(_id: String) -> void:
	velocity.x = 0.0

func _on_dialogue_finished() -> void:
	pass
