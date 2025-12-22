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
	for entity in entities:
		handle_entity_collisions(entity)

func create_item(new_position, item_type):
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
	entities.erase(box)

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

func place_random_box_entity(global_pos: Vector3, items: Array):
	place_box_entity(global_pos, full_boxes_atlas_coordinates.pick_random(), items)

func place_box_entity(global_pos: Vector3, atlas_coords: Vector2i, items: Array):
	var box = box_entity_instance.instantiate()
	box.items = items
	add_child(box)
	box.set_coords(atlas_coords)
	box.set_real_position(global_pos)
	box_data[global_pos] = {"items": items}
	
	entities.append(box)

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
	#for voxel in get_voxels_in_aabb(aabb):
		#if box_data.has(voxel):
			#var block_aabb = AABB(voxel, Vector3.ONE)
			#if aabb.intersects(block_aabb):
				#_resolve_static_block_collision(entity, block_aabb)
	
	# Handle collisions with other boxes
	for other in entities:
		if other == entity: continue
		if aabb.intersects(other.get_aabb()):
			_resolve_entity_collision(entity, other)
			
	# After all collision resolution, check toppling
	_check_support_and_topple(entity)

func _resolve_entity_collision(a, b):
	var a_aabb = a.get_aabb()
	var b_aabb = b.get_aabb()
	var overlap_x = min(a_aabb.position.x + a_aabb.size.x, b_aabb.position.x + b_aabb.size.x) - max(a_aabb.position.x, b_aabb.position.x)
	var overlap_y = min(a_aabb.position.y + a_aabb.size.y, b_aabb.position.y + b_aabb.size.y) - max(a_aabb.position.y, b_aabb.position.y)
	var overlap_z = min(a_aabb.position.z + a_aabb.size.z, b_aabb.position.z + b_aabb.size.z) - max(a_aabb.position.z, b_aabb.position.z)

	if overlap_x <= overlap_y and overlap_x <= overlap_z:
		# Resolve along X symmetrically
		var adjust = overlap_x / 2
		a.real_position.x -= adjust
		b.real_position.x += adjust
		a.velocity.x = 0
		b.velocity.x = 0
	elif overlap_y <= overlap_x and overlap_y <= overlap_z:
		# Resolve along Y symmetrically
		var adjust = overlap_y / 2
		a.real_position.y -= adjust
		b.real_position.y += adjust
		a.velocity.y = 0
		b.velocity.y = 0
	else:
		# Resolve along Z (vertical) → push only the one above
		if a_aabb.position.z > b_aabb.position.z:
			a.real_position.z += overlap_z
			a.velocity.z = 0
		else:
			b.real_position.z += overlap_z
			b.velocity.z = 0
	
	if overlap_z > 0 and a.real_position.z > b.real_position.z:
		a.velocity.x *= 0.125
		a.velocity.y *= 0.125


func _check_support_and_topple(entity, topple_strength := 0.0625):
	var a_aabb = entity.get_aabb()
	var bottom_z = a_aabb.position.z
	
	# Define 4 quadrant rectangles in XY plane
	var q = []
	var px = a_aabb.position.x
	var py = a_aabb.position.y
	var hx = a_aabb.size.x * 0.5
	var hy = a_aabb.size.y * 0.5
	
	q.append(Rect2(   px,    py, hx, hy)) # Q0 (top-left)
	q.append(Rect2(px+hx,    py, hx, hy)) # Q1 (top-right)
	q.append(Rect2(   px, py+hy, hx, hy)) # Q2 (bottom-left)
	q.append(Rect2(px+hx, py+hy, hx, hy)) # Q3 (bottom-right)
	
	var supported = [false, false, false, false]
	
	# --- CHECK SUPPORT ---
	for other in entities:
		if other == entity: continue
		
		var b_aabb = other.get_aabb()
		
		# Check touching in vertical axis (Z)
		var vertical_gap = bottom_z - (b_aabb.position.z + b_aabb.size.z)
		if abs(vertical_gap) > 0.05:
			continue
		
		# Rect for top of supporter in XY
		var br = Rect2(b_aabb.position.x, b_aabb.position.y, b_aabb.size.x, b_aabb.size.y)
		
		# Test each quadrant
		for i in range(4):
			if not supported[i]:
				var overlap = q[i].intersection(br)
				if overlap.has_area():
					supported[i] = true
		
		if supported[0] and supported[1] and supported[2] and supported[3]: 
			break # Break if it's allready fully supported
	
	# If NO quadrant is supported → entity is in free fall; do nothing
	if not (supported[0] or supported[1] or supported[2] or supported[3]):
		return
	
	# --- DETERMINE TOPPLE DIRECTION ---
	
	# Horizontal checks (left-right)
	var left_supported  = supported[0] or supported[2]
	var right_supported = supported[1] or supported[3]
	
	# Vertical checks (up-down)
	var up_supported    = supported[0] or supported[1]
	var down_supported  = supported[2] or supported[3]
	
	var dir = Vector2.ZERO
	
	# Missing two adjacent quadrants → topple
	if not up_supported:
		dir.y = -1  # topple upward
	elif not down_supported:
		dir.y = 1   # topple downward
	elif not left_supported:
		dir.x = -1  # topple left
	elif not right_supported:
		dir.x = 1   # topple right
	
	if dir == Vector2.ZERO:
		return  # stable
	
	# Apply movement
	entity.velocity.x += dir.x * topple_strength
	entity.velocity.y += dir.y * topple_strength
	
	# Animate topple
	if entity is BoxEntity:
		entity.move(Vector2i(dir.x, dir.y))

func __check_support_and_topple(entity, topple_threshold := 0.4, topple_strength := .0625):
	var a_aabb = entity.get_aabb()
	var bottom_z = a_aabb.position.z
	var support_found = false
	var max_overlap_area = 0.0
	var best_supports : int = 0
	var best_support_center : Vector3 = Vector3.ZERO
	
	for other in entities:
		if other == entity: continue
		
		var b_aabb = other.get_aabb()
		
		# Check only supports directly below (touching in Z)
		var vertical_gap = bottom_z - (b_aabb.position.z + b_aabb.size.z)
		if abs(vertical_gap) > 0.05: # small tolerance
			continue
		
		# Overlap region in XY plane
		var overlap_x = min(a_aabb.position.x + a_aabb.size.x, b_aabb.position.x + b_aabb.size.x) - max(a_aabb.position.x, b_aabb.position.x)
		var overlap_y = min(a_aabb.position.y + a_aabb.size.y, b_aabb.position.y + b_aabb.size.y) - max(a_aabb.position.y, b_aabb.position.y)
		
		if overlap_x > 0 and overlap_y > 0:
			var overlap_area = overlap_x * overlap_y
			max_overlap_area += overlap_area
			
			best_support_center += b_aabb.get_center()
			best_supports += 1
			
			support_found = true
	
	if not support_found:
		# No support → gravity already pulls it down
		return
	
	best_support_center /= best_supports
	
	# How much of its base is supported?
	var base_area = a_aabb.size.x * a_aabb.size.y
	var support_ratio = max_overlap_area / base_area
	
	if support_ratio < topple_threshold:
		# Topple sideways: push entity away from center of support
		var dir_x = a_aabb.get_center().x - best_support_center.x
		var dir_y = a_aabb.get_center().y - best_support_center.y
		
		if abs(dir_x) > abs(dir_y):
			entity.velocity.x += topple_strength * sign(dir_x)
			if entity is BoxEntity: entity.move(Vector2i(sign(dir_x), 0))
		else:
			entity.velocity.y += topple_strength * sign(dir_y)
			if entity is BoxEntity: entity.move(Vector2i(0, sign(dir_y)))
