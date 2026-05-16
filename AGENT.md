# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the game

Open `test-game-project/` in **Godot 4.6** and press F5. The main scene is `scenes/TitleScreen.tscn`. There is no CLI build step — all development happens inside the Godot editor or via GDScript edits.

## Critical constraint: no editor interaction

**All gameplay content must be created in GDScript.** The user provides assets only. Never ask the user to paint tiles, configure nodes, or do anything in the Godot editor. Specifically:
- TileMap tiles are placed via `TileMap.set_cell()` in `scripts/Level.gd`
- TileSets are built at runtime in `scripts/LevelTileMap.gd` from a texture path export
- `SpriteFrames` for the player are constructed programmatically in `Player._setup_sprites()`

## Architecture

### Autoloads (always available as globals)
- **`DialogueManager`** (`scripts/autoloads/DialogueManager.gd`) — CanvasLayer (layer 50). Loads all JSON from `data/dialogue/`, exposes `start_dialogue(id)`, emits `dialogue_started` / `dialogue_finished`. Builds its own Panel UI at runtime. Blocks player input while active via `is_active()`.
- **`SceneManager`** (`scripts/autoloads/SceneManager.gd`) — CanvasLayer (layer 100). `change_scene(path)` fades to black, switches scene, fades in. Guards double-calls with `_fading`.
- **`AudioManager`** (`scripts/autoloads/AudioManager.gd`) — Node. Creates "Music" and "SFX" audio buses at runtime if missing. `play_music(path)` / `stop_music()` / `play_sfx(path)`.

### Scene flow
```
TitleScreen.tscn  →(Space)→  Level01.tscn  →(LevelExit trigger)→  Level02.tscn
```

### Level scenes
Each level scene (`scenes/levels/LevelXX.tscn`) has:
- Root `Node2D` with `scripts/Level.gd` — exports `music_path` and `level_index`
- `TileMap` node with `scripts/LevelTileMap.gd` — export `atlas_texture_path` to select tileset image
- `Player` (`CharacterBody2D` + `scripts/Player.gd`) with a child `Camera2D`
- `EventTrigger` nodes (`Area2D` + `scripts/EventTrigger.gd`) — fire dialogue and/or scene transitions

### Adding a new level
1. Add a `_build_level_NN(tm: TileMap)` function to `scripts/Level.gd` and add a `match` branch for the new index.
2. Create `scenes/levels/LevelNN.tscn` following the pattern of Level01/02. Set `level_index` on the root node and `atlas_texture_path` on TileMap.
3. Set the preceding level's `LevelExit` trigger `next_scene` to point to the new scene.

### Tile placement (`Level.gd`)
Uses the `_fill(tm, src, surface, fill, col0, col1, row0, row1)` helper:
- `src` — TileSetAtlasSource ID (always 0, the only source)
- `surface` — `Vector2i` atlas coord for the top row of a fill
- `fill` — `Vector2i` atlas coord for all rows below the top
- Coordinates are in tile units (1 tile = 16px)

Level01 tileset (`tilemapblack.png`, 10×2): `SURFACE = Vector2i(1,0)`, `FILL = Vector2i(1,1)`  
Level02 tileset (`New Piskel.png`, 2×2): `SURFACE = Vector2i(0,0)`, `FILL = Vector2i(0,1)`

### Dialogue system
Dialogue lives in `data/dialogue/chapter_01.json`. Format:
```json
{
  "some_id": {
    "lines": [
      { "speaker": "Elizabeth", "portrait": "Tired", "text": "..." }
    ]
  }
}
```
`portrait` values are short keys resolved via `PORTRAIT_MAP` in `DialogueManager.gd` (e.g. `"Tired"`, `"Shocked"`, `"Happy"` — see the map for all valid keys). `EventTrigger` fires dialogue by `dialogue_id`; if `next_scene` is also set, it changes scene after the last line via `CONNECT_ONE_SHOT` on `dialogue_finished`.

### Player sprite alignment
The player sprite is 16×16px rendered at 4× scale (64×64px). The collision box is `Vector2(10, 22)`. Sprite offset is `Vector2(0, -21)` to align the sprite's feet with the bottom of the collision shape (half-height 11 − half-sprite 32 = −21).

## Input map
| Action | Keys |
|--------|------|
| `move_left` | A, Left arrow |
| `move_right` | D, Right arrow |
| `jump` | W, Up arrow |
| `dash` | Space |

`ui_accept` (Enter / Space) is used alongside `dash` for dialogue advance. Do not use `ui_interact` — it is not defined.

## Asset conventions
- All sprites are 16×16px pixel art; the project uses nearest-neighbour filtering (`default_texture_filter=0`)
- Viewport: 960×540, `canvas_items` stretch mode
- Audio: `.wav` for SFX/music; play exclusively through `AudioManager` — never `AudioStreamPlayer` nodes in scenes
- Portrait images live in `assets/sprites/Dialog_UI/` and are referenced by short name via `PORTRAIT_MAP`
