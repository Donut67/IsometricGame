extends Node2D
class_name Structure

var structure_type: String  # e.g., "scrap_smelter"
@export var size: Vector3i = Vector3i(1, 1, 1)
var facing_dir: Vector3i = Vector3i(1, 0, 0) # Default facing "right" in grid space

var input_inventory: Array = []
var input_capacity: int = 8
var output_inventory: Array = []
var output_capacity: int = 4

var current_recipe: Dictionary = {}
var progress: float = 0.0

var directions = {
	Vector3i( 0, -1, 0): Vector2i(0, 0),
	Vector3i( 1,  0, 0): Vector2i(1, 0),
	Vector3i( 0,  1, 0): Vector2i(2, 0),
	Vector3i(-1,  0, 0): Vector2i(3, 0),
}

func _ready():
	size = Vector3i(1, 1, 1)
	
	var shader = load("res://Assets/outline.gdshader")
	$TileMapLayer.material = ShaderMaterial.new()
	$TileMapLayer.material.set("shader", shader)
	$TileMapLayer.material.set("shader_parameter/width", 0)

func _process(delta: float) -> void:
	if current_recipe:
		progress += delta
		if progress >= current_recipe.time:
			_finish_recipe()

func get_real_position() -> Vector3:
	return Global.screen_to_grid(global_position, 0)

func highlight(value: bool):
	$TileMapLayer.material.set("shader_parameter/width", 1 if value else 0)

func set_direction(facing: Vector3i):
	facing_dir = facing
	
	var new_coords = $TileMapLayer.get_cell_atlas_coords(Vector2i(-1, 0)) + directions[facing]
	$TileMapLayer.set_cell(Vector2i(-1, 0), 1, new_coords)

func add_item(item: String) -> bool:
	if input_inventory.size() == input_capacity: return false
	
	input_inventory.append(item)
	_try_start_recipe()
	
	return true

func take_item() -> Variant:
	if output_inventory.size() > 0:
		var result = output_inventory.pop_front()
		_try_start_recipe()
		return result
	return null

func _try_start_recipe() -> void:
	if current_recipe or output_inventory.size() == output_capacity: return

	var recipe = Global.find_structure_recipe(input_inventory, structure_type)
	if recipe.size() > 0:
		current_recipe = recipe
		progress = 0.0

func _finish_recipe() -> void:
	for input_item in current_recipe.input:
		input_inventory.erase(input_item) # remove each required input once
	
	var output_item = current_recipe.output
	if _can_output_to_world():
		_generate_output(output_item)
	else:
		output_inventory.append(output_item)
	
	current_recipe = {}
	_try_start_recipe()

func _can_output_to_world() -> bool:
	var output_pos = _get_output_tile_pos()
	return Global.is_tile_empty(output_pos)

func _get_output_tile_pos() -> Vector3i:
	# Assuming structure position is aligned to grid
	var grid_pos = Global.screen_to_grid(global_position, 0)
	return grid_pos + facing_dir

func _generate_output(item_type: String):
	var from = Global.screen_to_grid_f(global_position, 0) + Vector3(.5, .5, .5) * Vector3(facing_dir)
	var item = Global.create_item(item_type, from)
	
	var front = from + Vector3(facing_dir) + Vector3(randf() * 1.5 - .75, randf() * 1.5 - .75, 1)
	var dir_vector = (front - from).normalized()
	
	item.velocity = Vector3(5, 5, 7.5) * dir_vector
	
	return item
