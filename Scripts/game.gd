extends Node2D

@onready var interact_layer = $TileMapLayer
@onready var world: World = $MapLayers
@onready var mouse_area = $MouseArea
@onready var mouse_collision = $MouseArea/CollisionShape2D

@export var snap_threshold := 0.01
@export var mouse_query_radius := 8.0

var player : CharacterBody2D

# Track currently highlighted object
var closest_target: Node2D = null

# Categories for selection
var selection_categories = {
	"items": {
		"range_a": func(): return items_in_range,
		"range_b": func(): return player.items_in_range,
		"exclude": func(): return player.holding_item
	},
	"structures": {
		"range_a": func(): return structures_in_range,
		"range_b": func(): return player.structures_in_range,
		"exclude": func(): return null
	}
}

var items_in_range: Array = []
var structures_in_range: Array = []

var placement_position: Vector3i
var throw_height: float = 0
var charging_time: float = 0
var is_throw_charging: bool = false

var closest_item: Node2D = null
var closest_structure: Node2D = null

const player_instance = preload("res://Scenes/Entities/Player.tscn")
const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")
const item_instance = preload("res://Scenes/Objects/Item.tscn")

func _process(delta: float) -> void:
	mouse_area.global_position = get_global_mouse_position()
	
	var best_candidate : Node = null
	var best_dist := INF

	# Search all categories
	for category_data in selection_categories.values():
		var closest_in_category = _get_closest_valid(
			category_data["range_a"].call(),
			category_data["range_b"].call(),
			category_data["exclude"].call()
		)
		if closest_in_category:
			var dist = _dist_to_mouse(closest_in_category)
			if dist < best_dist:
				best_dist = dist
				best_candidate = closest_in_category

	_highlight_target(best_candidate)
	
	# Charge throw strenght
	if is_throw_charging:
		charging_time += delta
		
		if charging_time >= 0.5: 
			throw_height = min(throw_height + 5, 20)
			player.strenght.set_strenght(throw_height / 5)
			charging_time = 0
	
	var what_holding = null if player.holding_item == null else player.holding_item.get_groups()[0]
	
	if what_holding == null: mouse_collision.shape.radius = 1
	elif what_holding == "Tool": mouse_collision.shape.radius = 7
	else: mouse_collision.shape.radius = 3
	
	get_front_tile()

# ---------- Selection Helpers ----------

func _get_closest_valid(range_a: Array, range_b: Array, exclude : Node2D = null):
	var list = []
	for i in Global.intersect(range_a, range_b):
		if is_instance_valid(i) and i != exclude:
			list.append(i)
	return get_closest_item(get_global_mouse_position(), list) if list.size() > 0 else null

func _dist_to_mouse(obj) -> float:
	return obj.global_position.distance_to(get_global_mouse_position())

func _highlight_target(new_target: Node2D) -> void:
	# Remove highlight from old target if it's different
	if closest_target and closest_target != new_target:
		closest_target.highlight(false)

	# Apply highlight to the new target
	if new_target and new_target != closest_target:
		new_target.highlight(true)

	# Update reference
	closest_target = new_target

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ATTACK"):
		if player.holding_item == null: _handle_pickup()
		elif player.holding_item.get_groups()[0] == "Item" or player.holding_item.get_groups()[0] == "Tool": _handle_fusion()
		else: _handle_place()
	elif event.is_action_pressed("INTERACT"):
		if player.holding_item == null: _handle_retrieve_item()
		else: _handle_insert_item()
	elif event.is_action_pressed("THROW"):
		_handle_throw_start()
	elif event.is_action_released("THROW"):
		_handle_throw_release()
	elif event.is_action_pressed("SCROLL_UP"):
		placement_position.z = min(placement_position.z + 1, 11)
	elif event.is_action_pressed("SCROLL_DOWN"):
		placement_position.z = max(placement_position.z - 1, 0)

func _handle_pickup() -> void:
	#if closest_target != null and closest_target.is_in_group("Structure"): return
	
	var selected_tile = placement_position
	var selected_tile_coords = world.layers[0].get_cell_atlas_coords(Vector2i(selected_tile.x, selected_tile.y))
	
	if closest_target != null and closest_target.is_in_group("Item"):
		closest_target.set_real_position(Vector3.ZERO)
		closest_target.get_parent().remove_child(closest_target)
		world.entities.erase(closest_target)
		closest_target.apply_gravity = false
		
		player.set_holding_item(closest_target)
	elif world.box_data.has(selected_tile): 
		var box_entity = box_entity_instance.instantiate()
		player.set_holding_item(box_entity)
		
		box_entity.items = world.get_items(selected_tile)
		box_entity.set_grid_position(Vector3.ZERO, selected_tile_coords)
		box_entity.apply_gravity = false
		
		world.delete_box(selected_tile, true, false)
		world.box_data.erase(selected_tile)

func _handle_fusion() -> void:
	if closest_target != null and closest_target.is_in_group("PlacedStructure") and "trowel" in player.holding_item.item_type:
		Global.remove_structure_at(Global.screen_to_grid(closest_target.global_position, 0))
		
		var output = world.create_item(Global.screen_to_grid_f(get_global_mouse_position(), 0), closest_target.structure_type)
		world.throw_item(output, Global.screen_to_grid_f(get_global_mouse_position(), 0), Global.screen_to_grid_f(player.position, 0))
		
		return
	
	if closest_target != null and not closest_target.is_in_group("Item") or closest_target == null: return
	
	var input_types: Array[String] = [] # Array of the names of the item types in range, sorted by distance to the mouse_position
	var what_holding = player.holding_item.get_groups()[0]
	var items = []
	
	# Prepare inputs
	if what_holding == "Item":
		items = [player.holding_item, closest_target]
		
		input_types = [player.holding_item.item_type, closest_target.item_type]
	else:
		items = items_in_range.duplicate()
		items.sort_custom(func(a, b): return abs(a.position - get_global_mouse_position()) < abs(b.position - get_global_mouse_position()))
		items.erase(player.holding_item)
		
		for obj in items:
			input_types.append(obj.item_type)
	
	# Get recipe
	var recipe = Global.find_recipe(input_types, player.holding_item.item_type if what_holding == "Tool" else "")
	
	# Execute recipe if possible
	if recipe.has("output"):
		var output = world.create_item(Global.screen_to_grid_f(get_global_mouse_position(), 0), recipe["output"])
		world.throw_item(output, Global.screen_to_grid_f(get_global_mouse_position(), 0), Global.screen_to_grid_f(player.position, 0))
		
		# Play particle animation
		Global.play_landing_animation(get_global_mouse_position())
		
		var inputs = recipe["input"].duplicate()
		
		# Remove recipe ingredients
		for obj in items:
			if obj.item_type in inputs:
				inputs.erase(obj.item_type)
				if items_in_range.has(obj): items_in_range.erase(obj)
				if player.items_in_range.has(obj): player.items_in_range.erase(obj)
				if world.entities.has(obj): world.entities.erase(obj)
				obj.queue_free()
		
		if what_holding == "Item": player.holding_item = null

func _handle_place() -> void:
	if not player.holding_item: return
	
	var selected_tile = placement_position
	if _can_place_item(placement_position):
		var what_holding = player.holding_item.get_groups()[0]
		
		if what_holding == "BoxEntity":
			world.place_box(selected_tile, player.holding_item.atlas_coords, player.holding_item.items)
		elif what_holding == "Structure":
			var tile = Global.grid_to_screen(selected_tile)
			var pos  = player.position
			var direction
			
			if tile.x > pos.x: 
				if tile.y > pos.y: direction = Vector3i.LEFT
				else: direction = Vector3i.UP
			else:
				if tile.y > pos.y: direction = Vector3i.DOWN
				else: direction = Vector3i.RIGHT
			
			world.place_structure(selected_tile, player.holding_item.item_type, direction)
			#_try_fuse_multiblock(selected_tile) 
		player.remove_holding_item()

func _can_place_item(pos: Vector3i) -> bool:
	return not world.has_box(pos) and not world.has_structure(pos)

func _handle_retrieve_item() -> void:
	var selected_tile = placement_position
	var over_selected_tile_type = world.layers[1].get_cell_source_id(Vector2i(placement_position.x, placement_position.y))
	
	if not world.has_box(selected_tile) or over_selected_tile_type != -1: return 
	
	var items: Array = world.box_data[selected_tile]["items"]
	
	if items.size() != 0:
		var item = items.pop_back()
		world.add_child(item)
		world.entities.append(item)
		world.box_data[selected_tile] = {"items": items}
		item.set_real_position(Vector3(selected_tile) + Vector3.BACK)
		
		# Throw item towards the player
		var player_pos = Global.screen_to_grid_f(player.position, 0) + Vector3(randf() * 1 - .5, randf() * 1 - .5, 1)
		var dir_vector = (player_pos - Vector3(selected_tile) + Vector3.BACK).normalized() + Vector3.BACK
		item.velocity = Vector3(2.5, 2.5, 5) * dir_vector

func _handle_insert_item() -> void:
	var selected_tile = placement_position
	var is_structure = closest_target in structures_in_range
	
	if not is_structure and not world.has_space(selected_tile): return
	
	if not player.holding_item.item_type in Global.structure_atlas_coords[closest_target.structure_type][2]: return
	
	player.holding_item.get_parent().remove_child(player.holding_item)
	
	if is_structure:
		closest_target.add_item(player.holding_item.item_type)
	else: 
		world.put_item(selected_tile, player.holding_item)
	
	player.holding_item = null

func _handle_throw_start() -> void:
	is_throw_charging = player.holding_item != null
	throw_height = 0

func _handle_throw_release() -> void:
	if not player.holding_item: return
	if not is_throw_charging: return
	
	_throw_item(player.holding_item, throw_height)
	
	player.strenght.set_strenght(0)
	player.holding_item = null
	is_throw_charging = false

func _throw_item(item: Node, charge: float) -> void:
	var mouse_pos = Global.screen_to_grid_f(get_global_mouse_position(), 0)
	var player_pos = Global.screen_to_grid_f(player.position, 0)
	var dir_vector = (mouse_pos - player_pos).normalized() + Vector3(0, 0, 1)
	
	item.velocity = dir_vector * Vector3(20 if charge > 0 else 0, charge, 1) * Vector3(.5, .5, 1)
	
	if item.is_in_group("BoxEntity"):
		item.set_real_position(Global.screen_to_grid_f(item.global_position, .25), item.atlas_coords)
		world.box_entities.append(item)
	elif item.is_in_group("Item"):
		item.set_real_position(Global.screen_to_grid_f(item.global_position, .25))
		world.entities.append(item)
	
	# Detach item from player
	item.get_parent().remove_child(item)
	world.add_child(item)

func _try_fuse_multiblock(origin: Vector3i) -> void:
	for recipe in Global.multiblock_recipes:
		var recipes = [recipe, Global.get_alternative_pattern(recipe)]
		
		for variant in recipes:
			var pattern = variant["pattern"]
			var width   = variant["size"].x
			var height  = variant["size"].y
			
			for y in range(height):
				for x in range(width):
					var new_origin = origin - Vector3i(x, y, 0)
					if Global.check_pattern(new_origin, pattern):
						_fuse_multiblock(new_origin, recipe)
						return

func _fuse_multiblock(origin: Vector3i, recipe: Dictionary) -> void:
	var pattern = recipe["pattern"]
	var direction = Global.get_structure_at(origin).facing_dir
	
	for offset in pattern.keys():
		var pos = origin + offset
		Global.remove_structure_at(pos)
	
	world.place_structure(origin, recipe["output"], direction)

func get_front_tile():
	interact_layer.clear()
	
	var pre_z = placement_position.z
	placement_position = get_hover_tile()
	placement_position.z = pre_z
	
	interact_layer.set_cell(Vector2i(placement_position.x, placement_position.y), 0, Vector2i(1, 0))
	interact_layer.position = Vector2(-8, -4 - placement_position.z * 9)

func get_hover_tile(max_distance: float = 2.5) -> Vector3:
	var player_position = Global.screen_to_grid_f(player.global_position, 0)
	var mouse_position  = Global.screen_to_grid_f(get_global_mouse_position(), 0)
	
	var distance = mouse_position.distance_to(player_position)
	var dir_vector = (mouse_position - player_position).normalized()
	
	var clamped = player_position + dir_vector * min(distance, max_distance)
	return round(clamped)

func get_adjacent_tile_in_mouse_direction() -> Vector3i:
	var best_dir = player.directions.keys()[0]
	var player_pos = Global.screen_to_grid(player.position, 0)
	var best_dot = -INF
	var dir_vector = (get_global_mouse_position() - player.position).normalized()
	
	for dir in player.directions.keys():
		var screen_delta = Global.grid_to_screen(player_pos + Vector3i(dir.x, dir.y, 0)) - player.position
		var dot = dir_vector.dot(screen_delta.normalized())
		if dot > best_dot:
			best_dot = dot
			best_dir = dir
	
	var target_pos = player_pos + Vector3i(best_dir.x, best_dir.y, 0)
	target_pos.z = 0  # Only pick from bottom layer
	return target_pos

func sort_by_closest(item1, item2):
	return abs(item1.position - get_global_mouse_position()) < abs(item2.position - get_global_mouse_position())

func get_closest_item(objective: Vector2, items_list: Array) -> Node2D:
	if items_list.size() == 0: return null
	
	var closest = items_list[0]
	var dist = abs(closest.position - objective)
	
	for item in items_list:
		closest = closest if dist < abs(item.position - objective) else item
	
	return closest

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("Item"):
		items_in_range.append(area.owner)
	elif area.owner.is_in_group("PlacedStructure"):
		structures_in_range.append(area.owner)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if items_in_range.has(area.owner):
		items_in_range.erase(area.owner)
	elif structures_in_range.has(area.owner):
		structures_in_range.erase(area.owner)

# DEBUG
var solicitated_boxes = []

func _ready() -> void:
	player = player_instance.instantiate()
	player.position = Vector2(0, 0)
	
	var camera = Camera2D.new()
	camera.zoom = Vector2(3, 3)
	player.add_child(camera)
	
	world.add_child(player)
	
	solicitated_boxes.append(["carbon_dust", "metal_scrap", "carbon_dust", "metal_scrap", "basic_smelter", "metal_hammer"])
	solicitated_boxes.append(["basic_press"])
	
	for i in range(0):
		var possioble_items = ["", "metal_scrap", "carbon_dust", "plastic_chunk"]
		var box_items = []
		
		for j in range(5):
			var item = possioble_items.pick_random()
			if item == "": break
			box_items.append(item)
		
		solicitated_boxes.append(box_items)

func _on_timer_timeout() -> void:
	if solicitated_boxes.size() == 0: 
		$Timer.stop()
		return
	
	var types = solicitated_boxes.pop_front()
	var items = []
	
	for type in types:
		var item = item_instance.instantiate()
		item.set_item_type(type)
		items.append(item)
	
	world.place_random_box_entity(Vector3i(0, 0, 31), items)
