extends Structure
class_name ComplexStructure

func set_direction(facing: Vector3i):
	var directions = {
		Vector3i( 0, -1, 0): Vector2i(0, 0),
		Vector3i( 1,  0, 0): Vector2i(0, 0),
		Vector3i( 0,  1, 0): Vector2i(1, 0),
		Vector3i(-1,  0, 0): Vector2i(1, 0),
	}
	
	facing_dir = facing
	
	var new_coords = $TileMapLayer.get_cell_atlas_coords(Vector2i(-1, 0)) + directions[facing]
	$TileMapLayer.set_cell(Vector2i(-1, 0), 2 , new_coords)
