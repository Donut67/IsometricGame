extends Node2D

@export var grid_size: Vector2i = Vector2i(48, 48)

@export var pile_count:  int = 8
@export var min_height:  int = 3
@export var max_height:  int = 6
@export var pile_radius: int = 4  # Max horizontal radius from center

@onready var shadow_layer: TileMapLayer  = $Shadows
@onready var layers: Array[TileMapLayer] = [
	$TileMapLayer1, $TileMapLayer2,  $TileMapLayer3,  $TileMapLayer4, 
	$TileMapLayer5, $TileMapLayer6,  $TileMapLayer7,  $TileMapLayer8, 
	$TileMapLayer9, $TileMapLayer10, $TileMapLayer11, $TileMapLayer12
]
@onready var tile_size: Vector2i = shadow_layer.tile_set.tile_size

var heightmap: Dictionary = {}
var box_entities = []
var updates: Dictionary = {"deleted": []}
var box_data: Dictionary = {}  # Key: Vector3i, Value: Dictionary with data, e.g. {"item": item}

const SHADOW_HALF: Vector2i = Vector2i(0, 0)
const SHADOW_FULL: Vector2i = Vector2i(1, 0)
const full_boxes_atlas_coordinates = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 0), Vector2i(0, 1), 
	Vector2i(1, 1), Vector2i(4, 1), Vector2i(0, 4), Vector2i(1, 4), 
	Vector2i(2, 4), Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 1)
]
const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")

func _process(delta: float) -> void:
	var to_process = updates["deleted"]
	updates["deleted"] = []
	
	for update in to_process:
		var pos = Vector2i(update.x, update.y)
		var height = update.z + 1
		
		if height == layers.size(): continue
		
		var box = layers[height].get_cell_atlas_coords(pos)
		var top = update + Vector3i(0, 0, 1)
		
		if box != Vector2i(-1, -1):
			delete_box(top, true, false)
			place_box_entity(top, box, box_data[top]["item"])
			box_data.erase(top)
	
	# Proces entities
	for box in box_entities:
		var pos = Vector3i((box.real_position).floor())
		var map_pos = Vector2i(pos.x, pos.y)
		
		# If the box is ober the box height limit skip this box
		if pos.z >= layers.size(): continue
		
		var new_position = pos
		
		# If the box is lower that the ground place it on the floor or there is allerady a box on that position
		if pos.z < 0 or layers[pos.z].get_cell_source_id(map_pos) != -1:
			# Get the lowest possible height
			var height = pos.z + 1
			var found: bool = false
			
			while not found and height < 12:
				found = layers[height].get_cell_source_id(map_pos) == -1
				if not found: height += 1
			
			if height - pos.z >= 3:
				# Rudimentary(bad) collision detection
				box.velocity *= Vector3(-1, -1, 1)
			elif found:
				# If there is a possible positions place the box there
				var possible_directions = can_fall(pos)
				if possible_directions[0] == Vector2i(0, 0):
					new_position = pos + Vector3i(0, 0, height - pos.z)
					from_entity_to_grid(box, new_position)
				else:
					var dir = possible_directions.pick_random()
					box.real_position += Vector3(dir.x, dir.y, 0)
			elif height == 12:
				# Otherwise, move the box to a side and let it fall
				var possible_directions = can_fall(pos)
				var dir = possible_directions.pick_random()
				box.real_position += Vector3(dir.x, dir.y, 0)

# From a position gives the diference in height with all it's immediete neighbors
func get_height_diferences(map_position: Vector3i):
	var position_2d = Vector2i(map_position.x, map_position.y)
	var current_height = map_position.z
	
	var dirs = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
	var diferences = {}
	
	for direction in dirs:
		diferences[direction] = current_height - get_height(position_2d + direction)
	
	return diferences

# Returns the directions where the diference is higher that tolerance
func can_fall(map_position: Vector3i, tolerance: int = 3):
	var diferences = get_height_diferences(map_position)
	var possible_positions = []
	
	for dir in diferences.keys():
		if diferences[dir] >= tolerance: possible_positions.append(dir)
	
	return possible_positions if possible_positions.size() > 0 else [Vector2i(0, 0)]

# Places entity box to the grid
func from_entity_to_grid(box: BoxEntity, new_position: Vector3i):
	place_box(new_position, box.atlas_coords, box.item)
	box.delete_box()
	box_entities.erase(box)

func place_random_box(global_pos: Vector3i, item: Object, reload_shadows: bool = true):
	place_box(global_pos, full_boxes_atlas_coordinates.pick_random(), item, reload_shadows)

func place_box(global_pos: Vector3i, coords: Vector2i, item: Object, reload_shadows: bool = true):
	var pos = Vector2i(global_pos.x, global_pos.y)
	var fall_z = global_pos.z
	
	layers[fall_z].set_cell(pos, 1, coords, 0)
	
	heightmap[pos] = max(heightmap.get(pos, -1), fall_z + 1)
	box_data[global_pos] = {"item": item}
	
	if reload_shadows: place_shadows()

func place_random_box_entity(global_pos: Vector3i, item: Object):
	place_box_entity(global_pos, full_boxes_atlas_coordinates.pick_random(), item)

func place_box_entity(global_pos: Vector3i, atlas_coords: Vector2i, item: Object):
	var box = box_entity_instance.instantiate()
	box.item = item
	add_child(box)
	box.set_grid_position(global_pos, atlas_coords)
	box_data[global_pos] = {"item": item}
	
	box_entities.append(box)

func place_shadows():
	shadow_layer.clear()
	
	for pos in heightmap.keys():
		var height = heightmap[pos]
		
		for i in range(1, height + 1):
			var shadow_pos = Vector2i(pos.x + i, pos.y)
			if shadow_layer.get_cell_atlas_coords(shadow_pos) == SHADOW_FULL: continue
			shadow_layer.set_cell(shadow_pos, 2, SHADOW_HALF if i == height else SHADOW_FULL, 0)

func delete_box(pos: Vector3i, update: bool = true, cascade: bool = true):
	var min_layer = pos.z
	var map_pos = Vector2i(pos.x, pos.y)
	
	layers[min_layer].set_cell(map_pos)
	if cascade:
		for layer in range(min_layer + 1, max_height):
			var current_layer = layer - 1
			var atlas_coords = layers[layer].get_cell_atlas_coords(map_pos)
			
			layers[current_layer].set_cell(map_pos, 1, atlas_coords, 0)
		
	heightmap[map_pos] = max(0, heightmap[map_pos] - 1)
	
	if update: 
		place_shadows()
		updates["deleted"].append(pos)

func get_height(map_position):
	return heightmap.get(map_position, 0)
