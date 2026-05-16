## Configures a TileSet from a texture atlas at runtime.
## Attach to a TileMap node and set atlas_texture_path and tile_size_px.
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

	var texture := load(atlas_texture_path) as Texture2D
	if texture == null:
		push_warning("LevelTileMap: failed to load texture: " + atlas_texture_path)
		return

	var ts := TileSet.new()
	ts.tile_size = tile_size_px

	if physics_layer_enabled:
		ts.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = tile_size_px
	var source_id := ts.add_source(source)
	source = ts.get_source(source_id) as TileSetAtlasSource

	var tex_size: Vector2i = texture.get_size()
	var cols := int(tex_size.x / tile_size_px.x)
	var rows := int(tex_size.y / tile_size_px.y)

	for row in range(rows):
		for col in range(cols):
			var coord := Vector2i(col, row)
			source.create_tile(coord)
			if physics_layer_enabled:
				var td := source.get_tile_data(coord, 0)
				var poly := PackedVector2Array([
					Vector2(0, 0),
					Vector2(tile_size_px.x, 0),
					Vector2(tile_size_px.x, tile_size_px.y),
					Vector2(0, tile_size_px.y),
				])
				td.set_collision_polygons_count(0, 1)
				td.set_collision_polygon_points(0, 0, poly)

	tile_set = ts
	print("LevelTileMap: built tileset from ", atlas_texture_path,
			" - %d x %d tiles." % [cols, rows])
