## Configures a TileSet from a texture atlas at runtime.
## Attach to a TileMap node. Set atlas_texture_path and tile_size before running.
## After first run, paint tiles in the Godot editor using the TileMap panel.
extends TileMap

@export var atlas_texture_path: String = ""
@export var tile_size_px: Vector2i = Vector2i(16, 16)
@export var physics_layer_enabled: bool = true

func _ready() -> void:
	if atlas_texture_path == "" or tile_set != null:
		return
	_build_tileset()

func _build_tileset() -> void:
	if not ResourceLoader.exists(atlas_texture_path):
		push_warning("LevelTileMap: texture not found: " + atlas_texture_path)
		return

	var ts := TileSet.new()
	ts.tile_size = tile_size_px

	if physics_layer_enabled:
		ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = load(atlas_texture_path)
	source.texture_region_size = tile_size_px

	# Compute atlas grid dimensions from texture size
	var tex_size: Vector2i = source.texture.get_size()
	var cols := tex_size.x / tile_size_px.x
	var rows := tex_size.y / tile_size_px.y

	for row in rows:
		for col in cols:
			var coord := Vector2i(col, row)
			source.create_tile(coord)
			if physics_layer_enabled:
				# Give every tile a full-square collision shape
				var td := source.get_tile_data(coord, 0)
				var poly := PackedVector2Array([
					Vector2(-tile_size_px.x * 0.5, -tile_size_px.y * 0.5),
					Vector2( tile_size_px.x * 0.5, -tile_size_px.y * 0.5),
					Vector2( tile_size_px.x * 0.5,  tile_size_px.y * 0.5),
					Vector2(-tile_size_px.x * 0.5,  tile_size_px.y * 0.5),
				])
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, poly)

	ts.add_source(source)
	tile_set = ts
	print("LevelTileMap: built tileset from ", atlas_texture_path,
			" — %d×%d tiles." % [cols, rows])
