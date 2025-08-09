extends Node2D

@onready var player = $MapLayers/Player
@onready var interact_layer = $TileMapLayer
@onready var world = $MapLayers
@onready var mouse_area = $Area2D

var placement_position: Vector2i
var throw_height: float = 0
var charging_time: float = 0
var is_thow_charging: bool = false
var items_in_range: Array = []
var closest_item: Node2D = null

const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")
const item_instance = preload("res://Scenes/Objects/Item.tscn")

func _process(delta: float) -> void:
	mouse_area.global_position = get_global_mouse_position()
	
	# Get closest item to the player
	var p_item_list = Global.intersect(items_in_range, player.items_in_range)
	var item_list = []
	for i in p_item_list: if is_instance_valid(i): item_list.append(i)
	
	if closest_item != null: closest_item.highlight(false)
	item_list.erase(player.holding_item)
	
	if item_list.size() != 0:
		closest_item = get_closest_item(get_global_mouse_position(), item_list)
		closest_item.highlight(true)
	else: closest_item = null
	
	# Charge throw strenght
	if is_thow_charging:
		charging_time += delta
		
		if charging_time >= 0.5: 
			throw_height = min(throw_height + 5, 20)
			player.strenght.set_strenght(floor(20 / (20 - throw_height)))
			charging_time = 0
	
	get_front_tile()

func _input(event: InputEvent) -> void:
	if event.is_action_released("ATTACK"):
		# If not holding anything and the selected tile is a box, pickup box
		# If not holding anything and no box on selected tile and item in range, pickup item
		# If holding box and no box on selected tile nor item in range, drop box
		# If holding box and item in range drop box and add item to box if box is empty
		# If holding item and item in range, fuse items and drop the fusion
		
		var what_holding = null if player.holding_item == null else player.holding_item.get_groups()[0]
		var selected_tile = Vector3i(placement_position.x, placement_position.y, 0)
		var selected_tile_type = world.layers[0].get_cell_source_id(placement_position)
		var selected_tile_coords = world.layers[0].get_cell_atlas_coords(placement_position)
		
		if what_holding == null:
			# If not holding anything
			
			if selected_tile_type == 0:
				# and the selected tile is a box, pickup box
				
				var box_entity = box_entity_instance.instantiate()
				player.set_holding_item(box_entity)
				
				box_entity.items = world.get_items(selected_tile)
				box_entity.set_grid_position(Vector3.ZERO, selected_tile_coords)
				box_entity.apply_gravity = false
				
				world.delete_box(selected_tile, true, false)
				world.box_data.erase(selected_tile)
			elif closest_item != null:
				# and no box on selected tile and item in range, pickup item
				
				closest_item.set_real_position(Vector3.ZERO)
				closest_item.get_parent().remove_child(closest_item)
				closest_item.apply_gravity = false
				
				player.set_holding_item(closest_item)
		elif what_holding == "BoxEntity":
			# If player is holding a BoxEntinty and item in range, add item to box if box is empty
			if closest_item != null and player.holding_item.has_space():
				closest_item.get_parent().remove_child(closest_item)
				player.holding_item.put_item(closest_item)
			
			# drop box if has space
			if selected_tile_type == -1:
				world.place_box(selected_tile, player.holding_item.atlas_coords, player.holding_item.items)
				player.remove_holding_item()
		elif what_holding == "Structure" and selected_tile_type == -1:
			# If player is holding a Structure and nothing on the selected tile
			
			var atlas_coords = Global.get_structure_atlas_coords(player.holding_item.item_type)
			var structure = Global.get_structure_scene(player.holding_item.item_type).instantiate()
			structure.position = Global.grid_to_screen(selected_tile)
			add_child(structure)
			
			world.place_structure(selected_tile, atlas_coords, Vector2i.DOWN)
			player.remove_holding_item()
		elif what_holding == "Item":
			# If holding item and item in range, try fuse items and drop the fusion
				
			var recipe = Global.find_recipe([player.holding_item.item_type, closest_item.item_type])
			
			if recipe.has("output"):
				create_item_and_throw(closest_item.real_position, recipe["output"], selected_tile)
				
				# Remove the input items
				items_in_range.erase(closest_item)
				player.items_in_range.erase(closest_item)
				
				items_in_range.erase(player.holding_item)
				player.items_in_range.erase(player.holding_item)
				
				closest_item.queue_free()
				closest_item = null
				player.remove_holding_item()
		elif what_holding == "Tool":
			# If holding tool and items in range, try fuse items and drop the fusion
			
			var items = items_in_range.duplicate()
			items.sort_custom(func(a, b): return abs(a.position - get_global_mouse_position()) < abs(b.position - get_global_mouse_position()))
			items.erase(player.holding_item)
			
			var types_array: Array[String] = [] # Array of the names of the item types in range, sorted by distance to the mouse_position
			for obj in items:
				types_array.append(obj.item_type)
			
			var recipe = Global.find_advanced_recipe(types_array, player.holding_item.item_type)
			
			if recipe.has("output"):
				create_item_and_throw(Global.screen_to_grid_f(get_global_mouse_position(), 0), recipe["output"], selected_tile)
				
				var inputs = recipe["input"].duplicate()
				
				for obj in items:
					if obj.item_type in inputs:
						inputs.erase(obj.item_type)
						items_in_range.erase(obj)
						player.items_in_range.erase(obj)
						obj.queue_free()
	elif event.is_action_released("INTERACT"):
		# If not holding anything and the selected tile is a box, take item from box
		# If holding item and selected tile is box and has space, put item in the box
		
		var what_holding = null if player.holding_item == null else player.holding_item.get_groups()[0]
		var selected_tile = Vector3i(placement_position.x, placement_position.y, 0)
		var selected_tile_type = world.layers[0].get_cell_source_id(placement_position)
		var over_selected_tile_type = world.layers[1].get_cell_source_id(placement_position)
		
		if what_holding == null and over_selected_tile_type == -1 and world.has_space(selected_tile) and world.box_data.has(selected_tile):
			# If not holding anything and the selected tile is a box, take last item from the box
			
			var items: Array = world.box_data[selected_tile]["items"]
			
			if items.size() != 0:
				var item = items.pop_back()
				add_child(item)
				world.entities.append(item)
				world.box_data[selected_tile] = {"items": items}
				item.real_position = Vector3(selected_tile) + Vector3(0, 0, 1)
				
				# Throw item towards the player
				var player_pos = Global.screen_to_grid_f(player.position, 0)
				var dir_vector = (player_pos - Vector3(selected_tile)).normalized() + Vector3(randf() * 2 - 1, randf() * 2 - 1, 1)
				item.velocity = Vector3(2.5, 2.5, 5) * dir_vector
		elif what_holding == "Item" and world.has_space(selected_tile) and selected_tile_type == 0:
			# If holding item and selected tile is box and has space, put item in the box
			
			player.holding_item.get_parent().remove_child(player.holding_item)
			world.put_item(selected_tile, player.holding_item)
			player.holding_item = null
	elif event.is_action_pressed("THROW"):
		# Start throwing charge if player is holding something
		
		is_thow_charging = player.holding_item != null
		throw_height = 5
	elif event.is_action_released("THROW") and is_thow_charging:
		# Throw the holding item
		
		var item: Node = player.holding_item
		var pos = item.global_position
		
		# Detach item from player
		item.get_parent().remove_child(item)
		
		# Throw towards the mouse position
		var mouse_pos = Global.screen_to_grid_f(get_global_mouse_position(), 0)
		var player_pos = Global.screen_to_grid_f(player.position, 0)
		var dir_vector = (mouse_pos - player_pos).normalized() + Vector3(0, 0, 1)
		
		item.velocity = dir_vector * throw_height * Vector3(.5, .5, 1)
		
		if item.is_in_group("BoxEntity"):
			item.set_real_position(Global.screen_to_grid_f(pos, 1), item.atlas_coords) 
			world.box_entities.append(item)
		elif item.is_in_group("Item"):
			item.set_real_position(Global.screen_to_grid_f(pos, 1)) 
		
		world.add_child(item)
		world.entities.append(item)
		
		# Reset throwing variables
		throw_height = 0
		player.strenght.set_strenght(0)
		player.holding_item = null
		charging_time = 0
		is_thow_charging = false

# The item thrown goes to the player's direction
func create_item_and_throw(new_position, item_type, selected_tile):
	var item = item_instance.instantiate()
	item.set_item_type(item_type)
	item.real_position = new_position
	add_child(item)
	world.entities.append(item)
	
	# Throw item towards the player
	throw_item(item, Vector3(selected_tile), Global.screen_to_grid_f(player.position, 0))

func throw_item(item, from, to):
	var dir_vector = (to - from).normalized()
	var noise = Vector3(randf() * 2 - 1, randf() * 2 - 1, 1)
	
	item.velocity = Vector3(-2.5, -2.5, 3.125) * (dir_vector + noise)

func get_front_tile():
	interact_layer.clear()
	
	var pos = get_adjacent_tile_in_mouse_direction()
	placement_position = Vector2i(pos.x, pos.y)
	
	interact_layer.set_cell(placement_position, 0, Vector2i.ZERO)

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

func _on_area_2d_area_exited(area: Area2D) -> void:
	if items_in_range.has(area.owner):
		items_in_range.erase(area.owner)

# DEBUG
var solicitated_boxes = []

func _ready() -> void:
	solicitated_boxes.append(["scrap_smelter"])
	
	for i in range(60):
		var possioble_items = ["", "metal_scrap", "carbon_dust", "plastic_chunk"]
		var box_items = []
		
		for j in range(5):
			var item = possioble_items.pick_random()
			if item == "": break
			box_items.append(item)
		
		solicitated_boxes.append(box_items)

func _on_timer_timeout() -> void:
	var types = solicitated_boxes.pop_front()
	var items = []
	
	for type in types:
		var item = item_instance.instantiate()
		item.set_item_type(type)
		items.append(item)
	
	world.place_random_box_entity(Vector3i(0, 0, 31), items)
	
	if solicitated_boxes.size() == 0: $Timer.stop()
