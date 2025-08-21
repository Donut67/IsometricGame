extends Node2D
class_name World

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
var entities = []
var updates: Dictionary = {"deleted": []}
var box_data: Dictionary = {}
var structure_data: Dictionary = {}
var box_size: int = 5

const SHADOW_HALF: Vector2i = Vector2i(0, 0)
const SHADOW_FULL: Vector2i = Vector2i(1, 0)
const full_boxes_atlas_coordinates = [
	Vector2i(1, 0), Vector2i(3, 0), Vector2i(5, 0), Vector2i(7, 0), 
	Vector2i(1, 1), Vector2i(3, 1), Vector2i(5, 1), Vector2i(7, 1)
]

const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")
const item_instance = preload("res://Scenes/Objects/Item.tscn")

func _process(_delta: float) -> void:
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
			place_box_entity(top, box, box_data[top]["items"])
			box_data.erase(top)
	
	# Proces entities
	for box in box_entities:
		var pos = Vector3i((box.real_position).floor())
		var map_pos = Vector2i(pos.x, pos.y)
		
		# If the box is ober the box height limit skip this box
		if pos.z >= layers.size(): continue
		
		handle_entity_collisions(box)
		
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
					var new_position = pos + Vector3i(0, 0, height - pos.z)
					from_entity_to_grid(box, new_position)
				else:
					var dir = possible_directions.pick_random()
					box.real_position += Vector3(dir.x, dir.y, 0)
			elif height == 12:
				var possible_directions = can_fall(pos, 0)
				var dir = possible_directions.pick_random()
				box.real_position += Vector3(dir.x, dir.y, 0)
	
	for entity in entities:
		handle_entity_collisions(entity)

func create_item(new_position, item_type):
	print(item_type)
	var item = item_instance.instantiate()
	
	item.set_item_type(item_type)
	item.real_position = new_position
	add_child(item)
	entities.append(item)
	
	return item

func throw_item(item, from, to, normalized = true):
	var dir_vector = (to - from).normalized() if normalized else (to - from)
	var noise = Vector3.ZERO #Vector3(randf() * 2 - 1, randf() * 2 - 1, 1)
	
	item.velocity = Vector3(-2.5, -2.5, 3.125) * (dir_vector + noise)

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
func can_fall(map_position: Vector3i, tolerance: int = 1):
	var diferences = get_height_diferences(map_position)
	var possible_positions = []
	
	for dir in diferences.keys():
		if diferences[dir] >= tolerance: possible_positions.append(dir)
	
	return possible_positions if possible_positions.size() > 0 else [Vector2i(0, 0)]

# Places entity box to the grid
func from_entity_to_grid(box: BoxEntity, new_position: Vector3i):
	place_box(new_position, box.atlas_coords, box.items)
	box.delete_box()
	box_entities.erase(box)

func place_random_box(global_pos: Vector3i, items: Array, reload_shadows: bool = true):
	place_box(global_pos, full_boxes_atlas_coordinates.pick_random(), items, reload_shadows)

func place_box(global_pos: Vector3i, coords: Vector2i, items: Array, reload_shadows: bool = true):
	var pos = Vector2i(global_pos.x, global_pos.y)
	var fall_z = global_pos.z
	
	layers[fall_z].set_cell(pos, 0, coords, 0)
	
	heightmap[pos] = max(heightmap.get(pos, -1), fall_z + 1)
	box_data[global_pos] = {"items": items}
	
	if reload_shadows: place_shadows()

func place_structure(global_pos: Vector3i, structure_type: String, direction: Vector3i, reload_shadows: bool = true):
	var pos = Vector2i(global_pos.x, global_pos.y)
	var fall_z = global_pos.z
	
	var structure = Global.get_structure_scene(structure_type).instantiate()
	add_child(structure)
	
	structure.position = Global.grid_to_screen(global_pos)
	structure.set_direction(direction)
	
	var height = structure.size.z
	for x in range(structure.size.x):
		for y in range(structure.size.y):
			var offset = pos + Vector2i(x, y)
			heightmap[offset] = max(heightmap.get(offset, -1), fall_z + height)
			structure_data[global_pos + Vector3i(x, y, 0)] = structure
	
	if reload_shadows: place_shadows()

func place_random_box_entity(global_pos: Vector3i, items: Array):
	place_box_entity(global_pos, full_boxes_atlas_coordinates.pick_random(), items)

func place_box_entity(global_pos: Vector3i, atlas_coords: Vector2i, items: Array):
	var box = box_entity_instance.instantiate()
	box.items = items
	add_child(box)
	box.set_grid_position(global_pos, atlas_coords)
	box_data[global_pos] = {"items": items}
	
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
			
			layers[current_layer].set_cell(map_pos, 0, atlas_coords, 0)
		
	heightmap[map_pos] = max(0, heightmap[map_pos] - 1)
	
	if update: 
		place_shadows()
		updates["deleted"].append(pos)

func get_height(map_position):
	return heightmap.get(map_position, 0)

# Puts the item at the end of the list
func put_item(selected_tile: Vector3i, item: Object):
	if not has_space(selected_tile): return
	
	var items = []
	if box_data.has(selected_tile):
		items = box_data[selected_tile]["items"]
	
	items.append(item)
	box_data[selected_tile] = {"items": items}

func get_block(tile: Vector3i) -> Node2D:
	return box_data[tile] if tile in box_data else structure_data[tile] if tile in structure_data else null

func has_space(tile: Vector3i):
	return box_data.has(tile) and box_data[tile].size() < box_size

func is_tile_empty(tile: Vector3i) -> bool:
	return not has_box(tile) and not has_structure(tile)

func has_box(tile: Vector3i):
	return tile in box_data

func has_structure(tile: Vector3i):
	return tile in structure_data

func remove_structure(pos: Vector3i): 
	var map_pos = Vector2i(pos.x, pos.y)
	var structure_size = structure_data[pos].size
	
	layers[pos.z].set_cell(map_pos)
	structure_data[pos].queue_free()
	structure_data.erase(pos)
	
	var height = structure_size.z
	for x in range(structure_size.x):
		for y in range(structure_size.y):
			var offset = map_pos + Vector2i(x, y)
			heightmap[offset] = max(0, heightmap[offset] - height)
	
	place_shadows()

func get_items(selected_tile: Vector3i):
	if not box_data.has(selected_tile): return []
	
	return box_data[selected_tile]["items"]

# Returns the last inserted item and removes it from the list
func get_last_item(selected_tile: Vector2i):
	return get_nth_item(selected_tile, -1)

# Returns the nth inserted item and removes it from the list
func get_nth_item(selected_tile: Vector2i, index: int):
	if not box_data.has(selected_tile) or index >= box_data[selected_tile]["items"].size(): return null
	
	var items = box_data[selected_tile]["items"]
	var item = items[index]
	items.erase(item)
	
	box_data[selected_tile] = {"items": items}
	
	return item

# Physics
func get_voxels_in_aabb(aabb: AABB) -> Array:
	var voxels: Array = []
	
	var min_x = int(floor(aabb.position.x))
	var min_y = int(floor(aabb.position.y))
	var min_z = int(floor(aabb.position.z))
	var max_x = int(floor(aabb.position.x + aabb.size.x))
	var max_y = int(floor(aabb.position.y + aabb.size.y))
	var max_z = int(floor(aabb.position.z + aabb.size.z))
	
	for x in range(min_x, max_x+1):
		for y in range(min_y, max_y+1):
			for z in range(min_z, max_z+1):
				voxels.append(Vector3i(x, y, z))
	
	return voxels

func handle_entity_collisions(entity: Physics3DIsometric):
	var aabb: AABB = entity.get_aabb()
	
	# Handle world (static block) collisions
	for voxel in get_voxels_in_aabb(aabb):
		if box_data.has(voxel):
			var block_aabb = AABB(voxel, Vector3.ONE)
			if aabb.intersects(block_aabb):
				_resolve_static_block_collision(entity, block_aabb)
	
	# Handle collisions with other boxes
	for other in box_entities:
		if other == entity: continue
		if aabb.intersects(other.get_aabb()):
			_resolve_entity_collision(entity, other)

func _resolve_static_block_collision(entity, block_aabb: AABB):
	var entity_aabb = entity.get_aabb()
	var overlap_x = min(entity_aabb.position.x + entity_aabb.size.x, block_aabb.position.x + block_aabb.size.x) - max(entity_aabb.position.x, block_aabb.position.x)
	var overlap_y = min(entity_aabb.position.y + entity_aabb.size.y, block_aabb.position.y + block_aabb.size.y) - max(entity_aabb.position.y, block_aabb.position.y)
	var overlap_z = min(entity_aabb.position.z + entity_aabb.size.z, block_aabb.position.z + block_aabb.size.z) - max(entity_aabb.position.z, block_aabb.position.z)

	if overlap_x <= overlap_y and overlap_x <= overlap_z:
		entity.real_position.x += overlap_x if entity.velocity.x < 0 else -overlap_x
		entity.velocity.x = 0
	elif overlap_y <= overlap_x and overlap_y <= overlap_z:
		entity.real_position.y += overlap_y if entity.velocity.y < 0 else -overlap_y
		entity.velocity.y = 0
	else:
		entity.real_position.z += overlap_z if entity.velocity.z < 0 else -overlap_z
		entity.velocity.z = 0

func _resolve_entity_collision(a, b):
	var a_aabb = a.get_aabb()
	var b_aabb = b.get_aabb()
	var overlap_x = min(a_aabb.position.x + a_aabb.size.x, b_aabb.position.x + b_aabb.size.x) - max(a_aabb.position.x, b_aabb.position.x)
	var overlap_y = min(a_aabb.position.y + a_aabb.size.y, b_aabb.position.y + b_aabb.size.y) - max(a_aabb.position.y, b_aabb.position.y)
	var overlap_z = min(a_aabb.position.z + a_aabb.size.z, b_aabb.position.z + b_aabb.size.z) - max(a_aabb.position.z, b_aabb.position.z)

	if overlap_x <= overlap_y and overlap_x <= overlap_z:
		var adjust = overlap_x / 2
		a.real_position.x -= adjust
		b.real_position.x += adjust
		a.velocity.x = 0
		b.velocity.x = 0
	elif overlap_y <= overlap_x and overlap_y <= overlap_z:
		var adjust = overlap_y / 2
		a.real_position.y -= adjust
		b.real_position.y += adjust
		a.velocity.y = 0
		b.velocity.y = 0
	else:
		var adjust = overlap_z / 2
		a.real_position.z -= adjust
		b.real_position.z += adjust
		a.velocity.z = 0
		b.velocity.z = 0
