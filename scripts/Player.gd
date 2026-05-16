extends CharacterBody2D

# Movement
const SPEED := 150.0
const GRAVITY := 900.0
const MAX_FALL_SPEED := 600.0

# Jump
const JUMP_VELOCITY := -340.0
const MAX_JUMPS := 2
const JUMP_RELEASE_MULT := 0.45

# Coyote time & jump buffer
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.1

# Dash
const DASH_SPEED := 420.0
const DASH_DURATION := 0.18
const DASH_MAX_DURATION := 0.35
const DASH_COOLDOWN := 0.8

# Sprite display scale (16px sprite → 64px on screen)
const SPRITE_SCALE := Vector2(4, 4)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _jumps_left := MAX_JUMPS
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _was_on_floor := false

var _is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown := 0.0
var _dash_dir := 1
var _can_dash := true

var _in_air := false

func _ready() -> void:
	add_to_group("player")
	_setup_sprites()
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)

# ---------------------------------------------------------------------------
# Sprite frame setup (done in code so no Godot editor required)
# ---------------------------------------------------------------------------
func _setup_sprites() -> void:
	_sprite.scale = SPRITE_SCALE
	# Align sprite feet with collision bottom.
	# Collision half-height = 11, sprite half-height at 4x = 32 → offset = 11-32 = -21
	_sprite.position = Vector2(0, -21)

	var frames := SpriteFrames.new()

	# IDLE — two-frame blink cycle
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 3.0)
	frames.set_animation_loop("idle", true)
	_add_frame(frames, "idle", "res://assets/sprites/Player/Idle/idle.png", 4.0)
	_add_frame(frames, "idle", "res://assets/sprites/Player/Idle/bilnk'.png", 1.0)

	# WALK — vertical strip (16 × 144, 9 frames of 16×16)
	frames.add_animation("walk")
	frames.set_animation_speed("walk", 12.0)
	frames.set_animation_loop("walk", true)
	_add_strip(frames, "walk", "res://assets/sprites/Player/Run/RidingHoodRun (1).png",
			16, 16, 9, false)

	# JUMP — 9 individual files
	frames.add_animation("jump")
	frames.set_animation_speed("jump", 10.0)
	frames.set_animation_loop("jump", false)
	for i in range(1, 10):
		_add_frame(frames, "jump",
				"res://assets/sprites/Player/Jump/sprite_%02d.png" % i, 1.0)

	# SLEEPY — vertical strip (16 × 48, 3 frames of 16×16)
	frames.add_animation("sleepy")
	frames.set_animation_speed("sleepy", 4.0)
	frames.set_animation_loop("sleepy", true)
	_add_strip(frames, "sleepy", "res://assets/sprites/Player/Sleepy/Sleepy.png",
			16, 16, 3, false)

	_sprite.sprite_frames = frames
	_sprite.play("idle")

func _add_frame(frames: SpriteFrames, anim: String, path: String, duration: float) -> void:
	if not ResourceLoader.exists(path):
		return
	frames.add_frame(anim, load(path), duration)

func _add_strip(frames: SpriteFrames, anim: String, path: String,
		frame_w: int, frame_h: int, count: int, horizontal: bool) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		if horizontal:
			atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		else:
			atlas.region = Rect2(0, i * frame_h, frame_w, frame_h)
		frames.add_frame(anim, atlas, 1.0)

# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if DialogueManager.is_active():
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		_apply_gravity(delta)
		_play_anim("idle")
		move_and_slide()
		return

	var on_floor := is_on_floor()

	# Just landed
	if on_floor and not _was_on_floor:
		AudioManager.play_sfx("res://assets/audio/sfx/land.wav")
		_jumps_left = MAX_JUMPS
		_can_dash = true
		_in_air = false

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

	_dash_cooldown -= delta

	if Input.is_action_just_pressed("dash") and _can_dash and _dash_cooldown <= 0:
		_start_dash()

	if _is_dashing:
		_process_dash(delta)
		_play_anim("walk")
		move_and_slide()
		return

	_apply_gravity(delta)

	# Variable jump height: cut velocity when releasing jump early
	if velocity.y < 0 and not Input.is_action_pressed("jump"):
		velocity.y *= pow(JUMP_RELEASE_MULT, delta * 60.0)

	# Consume buffered jump
	if _jump_buffer_timer > 0:
		var can_ground_jump := _coyote_timer > 0 and _jumps_left == MAX_JUMPS
		if can_ground_jump:
			_do_jump(false)
		elif _jumps_left > 0 and not on_floor:
			_do_jump(true)

	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED

	if dir != 0:
		_dash_dir = int(sign(dir))
		_sprite.flip_h = dir < 0

	# Animation
	if not on_floor:
		_in_air = true
		_play_anim("jump")
	elif dir != 0:
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
	_in_air = true
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
	if _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(anim):
		return
	if _sprite.animation != anim:
		_sprite.play(anim)

func _on_dialogue_started(_id: String) -> void:
	velocity.x = 0.0

func _on_dialogue_finished() -> void:
	pass
