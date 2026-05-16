extends Node2D

@export var music_path: String = ""
@export var level_index: int = 1

func _ready() -> void:
	if music_path != "":
		AudioManager.play_music(music_path)
	_place_tiles()

func _place_tiles() -> void:
	var tm := $TileMap as TileMap
	if tm == null or tm.tile_set == null:
		return
	match level_index:
		1: _build_level_01(tm)
		2: _build_level_02(tm)

# ---------------------------------------------------------------------------
# Level 01 — Nyctophobia (Fear of the Dark)
# Tileset: tilemapblack.png  10×2 atlas of 16×16 tiles
# Jump height ≈ 4 tiles  |  Double jump ≈ 8 tiles  |  Dash ≈ 9 tiles wide
# ---------------------------------------------------------------------------
func _build_level_01(tm: TileMap) -> void:
	const SRC     := 0
	const SURFACE := Vector2i(1, 0)
	const FILL    := Vector2i(1, 1)

	_fill(tm, SRC, SURFACE, FILL,  0, 14, 32, 35)  # Starting ground
	# Gap A cols 15-17 (3 tiles — single jump)
	_fill(tm, SRC, SURFACE, FILL, 18, 32, 32, 35)  # Section 2
	# Gap B cols 33-36 (4 tiles — platform bridging)
	_fill(tm, SRC, SURFACE, FILL, 33, 36, 28, 28)  # Platform over gap B
	_fill(tm, SRC, SURFACE, FILL, 37, 54, 32, 35)  # Section 3
	_fill(tm, SRC, SURFACE, FILL, 45, 49, 27, 27)  # Bonus raised platform
	# Gap C cols 55-60 (6 tiles — double jump / dash challenge)
	_fill(tm, SRC, SURFACE, FILL, 56, 59, 26, 26)  # Mid-air platform over gap C
	_fill(tm, SRC, SURFACE, FILL, 61, 95, 32, 35)  # Final stretch
	_fill(tm, SRC, SURFACE, FILL, 70, 75, 23, 23)  # High platform (double-jump height)
	_fill(tm, SRC, SURFACE, FILL, 83, 90, 28, 35)  # Elevated ledge near exit

# ---------------------------------------------------------------------------
# Level 02 — Claustrophobia (Fear of Tight Spaces)
# Tileset: New Piskel.png  2×2 atlas of 16×16 cave tiles
# Low ceilings prevent double-jump; player must navigate carefully
# ---------------------------------------------------------------------------
func _build_level_02(tm: TileMap) -> void:
	const SRC     := 0
	const SURFACE := Vector2i(0, 0)
	const FILL    := Vector2i(0, 1)

	# Floor — full width with gaps
	_fill(tm, SRC, SURFACE, FILL,  0, 27, 30, 35)
	# Gap A cols 28-31 (bridged by platform)
	_fill(tm, SRC, SURFACE, FILL, 32, 41, 30, 35)
	# Gap B cols 42-46 (bridged by platform)
	_fill(tm, SRC, SURFACE, FILL, 47, 56, 30, 35)
	# Gap C cols 57-62 (bridged by platform)
	_fill(tm, SRC, SURFACE, FILL, 63, 90, 30, 35)

	# Ceiling — starts after opening to create claustrophobia
	# Ceiling low enough that single jump barely clears (row 5 = y80, jump height ~4 tiles)
	_fill(tm, SRC, FILL, FILL, 15, 90, 0, 4)

	# Platforms bridging gaps (must jump under low ceiling)
	_fill(tm, SRC, SURFACE, FILL, 28, 31, 22, 22)  # Gap A bridge (row 22)
	_fill(tm, SRC, SURFACE, FILL, 42, 46, 20, 20)  # Gap B bridge (row 20, even tighter)
	_fill(tm, SRC, SURFACE, FILL, 57, 62, 23, 23)  # Gap C bridge (row 23)

	# Mid-level platforms for verticality within constraints
	_fill(tm, SRC, SURFACE, FILL, 10, 14, 22, 22)
	_fill(tm, SRC, SURFACE, FILL, 35, 39, 18, 18)
	_fill(tm, SRC, SURFACE, FILL, 70, 76, 20, 20)

# ---------------------------------------------------------------------------
# Helper — fills a tile rectangle; top row gets SURFACE, rest get FILL
# ---------------------------------------------------------------------------
func _fill(tm: TileMap, src: int, surface: Vector2i, fill: Vector2i,
		col0: int, col1: int, row0: int, row1: int) -> void:
	for col in range(col0, col1 + 1):
		for row in range(row0, row1 + 1):
			tm.set_cell(0, Vector2i(col, row), src,
					surface if row == row0 else fill)
