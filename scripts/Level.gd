extends Node2D

@export var music_path: String = ""

func _ready() -> void:
	if music_path != "":
		AudioManager.play_music(music_path)
	_place_tiles()

# ---------------------------------------------------------------------------
# Tile placement — runs after children (TileMap._ready builds the TileSet first)
# ---------------------------------------------------------------------------
func _place_tiles() -> void:
	var tm := $TileMap as TileMap
	if tm == null or tm.tile_set == null:
		return
	_build_level_01(tm)

# ---------------------------------------------------------------------------
# Level 01 — Nyctophobia (Fear of the Dark) city night layout
#
# Tile grid: 16×16 px each. Viewport ≈ 60×33 tiles at 960×540.
# Player physics: jump height ~4 tiles, double-jump ~8 tiles,
#                 single-jump reach ~7 tiles wide, double ~15 tiles.
#
# Tile atlas coords (tilemapblack.png, 10×2 grid):
#   Surface  = (1, 0)  — top of ground (green/teal grass)
#   Fill     = (1, 1)  — underground solid fill
# ---------------------------------------------------------------------------
func _build_level_01(tm: TileMap) -> void:
	const SRC     := 0
	const SURFACE := Vector2i(1, 0)
	const FILL    := Vector2i(1, 1)

	# ── Section 1: Starting area (cols 0–14) ─────────────────────────
	_fill(tm, SRC, SURFACE, FILL,  0, 14, 32, 35)

	# ── Gap A (3 tiles: cols 15–17) — single jump required ───────────

	# ── Section 2 (cols 18–32) ────────────────────────────────────────
	_fill(tm, SRC, SURFACE, FILL, 18, 32, 32, 35)

	# ── Gap B (4 tiles: cols 33–36) — platform above ─────────────────
	#    Platform: cols 33–36, row 28 (slightly above ground, clears gap)
	_fill(tm, SRC, SURFACE, FILL, 33, 36, 28, 28)

	# ── Section 3 (cols 37–54) ────────────────────────────────────────
	_fill(tm, SRC, SURFACE, FILL, 37, 54, 32, 35)

	#    Bonus raised platform inside section 3 (cols 45–49, row 27)
	_fill(tm, SRC, SURFACE, FILL, 45, 49, 27, 27)

	# ── Gap C (6 tiles: cols 55–60) — double-jump / dash challenge ───
	#    Mid-air platform: cols 56–59, row 26
	_fill(tm, SRC, SURFACE, FILL, 56, 59, 26, 26)

	# ── Section 4: Final stretch (cols 61–95) ────────────────────────
	_fill(tm, SRC, SURFACE, FILL, 61, 95, 32, 35)

	#    High challenge platform (cols 70–75, row 23 — double-jump height)
	_fill(tm, SRC, SURFACE, FILL, 70, 75, 23, 23)

	#    Elevated ledge near level end (cols 83–90, rows 28–35)
	_fill(tm, SRC, SURFACE, FILL, 83, 90, 28, 35)

	print("Level01: tiles placed.")

# ---------------------------------------------------------------------------
# Helper — fills a rectangle of tiles; row_start gets SURFACE, rest get FILL
# ---------------------------------------------------------------------------
func _fill(tm: TileMap, src: int, surface: Vector2i, fill: Vector2i,
		col0: int, col1: int, row0: int, row1: int) -> void:
	for col in range(col0, col1 + 1):
		for row in range(row0, row1 + 1):
			tm.set_cell(0, Vector2i(col, row), src, surface if row == row0 else fill)
