extends TileMapLayer

var grid_position: Vector3i
var real_position: Vector3
var time_since_last_fall: float = 0
var atlas_coords: Vector2i

@onready var tile_size: Vector2i = tile_set.tile_size

func _process(delta: float) -> void:
	time_since_last_fall += delta
	var vel = Vector2(0, 9.8) * 16
	position += vel * time_since_last_fall * delta
	
	var aux_position = screen_to_grid(position, grid_position.z)
	grid_position.z = grid_position.z if aux_position == grid_position else grid_position.z - 1

func set_grid_position(grid_pos: Vector3i, coords: Vector2i):
	grid_position = grid_pos
	atlas_coords = coords
	
	set_cell(Vector2i(-1, 0), 1, coords)
	position = grid_to_screen(grid_pos)

# Convert grid position (Vector3i) → screen (Vector2)
func grid_to_screen(grid_pos: Vector3i) -> Vector2:
	var iso_x = (grid_pos.x - grid_pos.y) * tile_size.x / 2
	var iso_y = (grid_pos.x + grid_pos.y) * tile_size.y / 2 - grid_pos.z * tile_size.y
	return Vector2(iso_x, iso_y)

# Convert screen position (Vector2) + z → grid position (Vector3i)
func screen_to_grid(screen_pos: Vector2, z: int) -> Vector3i:
	# Remove vertical layer offset
	var adj_y = screen_pos.y + z * tile_size.y

	# Invert isometric projection
	var x = ((screen_pos.x / (tile_size.x / 2)) + (adj_y / (tile_size.y / 2))) / 2
	var y = ((adj_y / (tile_size.y / 2)) - (screen_pos.x / (tile_size.x / 2))) / 2

	return Vector3i(round(x), round(y), z)
