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

const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")

func _process(delta: float) -> void:
	mouse_area.global_position = get_global_mouse_position()
	
	
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
			# If the player is empty handed
			
			if selected_tile_type == 1:
				# Pickup Box
				
				var box_entity = box_entity_instance.instantiate()
				player.set_holding_item(box_entity)
				
				box_entity.item = world.box_data[selected_tile]["item"]
				box_entity.set_grid_position(Vector3.ZERO, selected_tile_coords)
				box_entity.apply_gravity = false
				
				world.delete_box(selected_tile, true, false)
				world.box_data.erase(selected_tile)
			elif items_in_range.size() > 0:
				# If not holding anything and no box on selected tile and item in range, pickup item
				
				var closest = get_closest_item(get_local_mouse_position())
				closest.set_real_position(Vector3.ZERO)
				closest.get_parent().remove_child(closest)
				closest.apply_gravity = false
				
				player.set_holding_item(closest)
		elif what_holding == "BoxEntity":
			# If player is holding a BoxEntinty
			
			if selected_tile_type == -1:
				# Drop Box
				
				var holding_atlas_coords = player.holding_item.atlas_coords
				var item = player.holding_item.item
				
				world.place_box(selected_tile, holding_atlas_coords, item)
				player.remove_holding_item()
			##
			## If holding box and item in range drop box and add item to box if box is empty
			##
		##
		## If holding item and item in range, fuse items and drop the fusion
		##
	elif event.is_action_released("INTERACT"):
		# If not holding anything and the selected tile is a box, take item from box
		# If holding item and selected tile is box and empty, put item in box
		
		var what_holding = null if player.holding_item == null else player.holding_item.get_groups()[0]
		var selected_tile = Vector3i(placement_position.x, placement_position.y, 0)
		var selected_tile_type = world.layers[0].get_cell_source_id(placement_position)
		var over_selected_tile_type = world.layers[1].get_cell_source_id(placement_position)
		var top = world.layers[1].get_cell_atlas_coords(placement_position)
		
		if what_holding == null and over_selected_tile_type == -1 and world.box_data.has(selected_tile):
			# Take the item from the box
			
			var item = world.box_data[selected_tile]["item"]
			add_child(item)
			world.box_data.erase(selected_tile)
			item.real_position = Vector3(selected_tile) + Vector3(0, 0, 1)
			
			# Throw item towards the player
			var player_pos = Global.screen_to_grid_f(player.position, 0)
			var dir_vector = (player_pos - Vector3(selected_tile)).normalized()
			item.velocity = Vector3(2.5, 0, 5) * dir_vector
		elif what_holding == "Item" and not world.box_data.has(selected_tile):
			# Put the holding item in the selected box
			
			player.holding_item.get_parent().remove_child(player.holding_item)
			world.box_data[selected_tile] = {"item": player.holding_item}
	elif event.is_action_pressed("THROW"):
		# Start throwing charge if player is holding something
		
		is_thow_charging = player.holding_item != null
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
		
		# Reset throwing variables
		throw_height = 0
		player.strenght.set_strenght(0)
		charging_time = 0
		is_thow_charging = false

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

func get_closest_item(objective: Vector2) -> Node2D:
	var closest = items_in_range[0]
	var dist = abs(closest.position - objective)
	
	for item in items_in_range:
		closest = closest if dist < abs(item.position - objective) else item
	
	return closest

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("Item"):
		items_in_range.append(area.owner)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if items_in_range.has(area.owner):
		items_in_range.erase(area.owner)
