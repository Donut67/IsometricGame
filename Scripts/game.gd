extends Node2D

@onready var player = $MapLayers/Player
@onready var interact_layer = $TileMapLayer
@onready var world = $MapLayers

var placement_position: Vector2i
var throw_height: float = 0
var charging_time: float = 0
var is_thow_charging: bool = false

const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")

func _process(delta: float) -> void:
	if is_thow_charging:
		charging_time += delta
		
		if charging_time >= 0.5: 
			throw_height = min(throw_height + 5, 20)
			player.strenght.set_strenght(floor(20 / (20 - throw_height)))
			charging_time = 0
	
	get_front_tile()

func _input(event: InputEvent) -> void:
	if event.is_action_released("ATTACK"):
		# if not holding anything and the selected tile is a box, pickup box
		# if not holding anything and no box on selected tile and item in range, pickup item
		# if holding box and no box on selected tile nor item in range, drop box
		# if holding box and item in range drop box and add item to box if box is empty
		# if holding item and selected tile is box and empty, put item in box
		# if holding item and item in range, fuse items and drop the fusion
		
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
			##
			## If not holding anything and no box on selected tile and item in range, pickup item
			##
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
		## If holding item and selected tile is box and empty, put item in box
		## If holding item and item in range, fuse items and drop the fusion
		##
	elif event.is_action_released("INTERACT"):
		var global_pos = Vector3i(placement_position.x, placement_position.y, 0)
		var top = world.layers[1].get_cell_atlas_coords(placement_position)
		
		if top == Vector2i(-1, -1):
			var item = world.box_data[global_pos]["item"]
			add_child(item)
			item.real_position = Vector3(global_pos) + Vector3(0, 0, 1)
			item.velocity = Vector3(2.5, 0, 5)
	elif event.is_action_pressed("THROW"):
		is_thow_charging = player.holding_item != null
	elif event.is_action_released("THROW") and is_thow_charging:
		var item: Node = player.holding_item
		var pos = item.global_position
		
		item.get_parent().remove_child(item)
		
		var mouse_pos = Global.screen_to_grid_f(get_global_mouse_position(), 0)
		var player_pos = Global.screen_to_grid_f(player.position, 0)
		var dir_vector = (mouse_pos - player_pos).normalized() + Vector3(0, 0, 1)
		
		item.velocity = dir_vector * throw_height * Vector3(.5, .5, 1)
		item.set_real_position(Global.screen_to_grid_f(pos, 1), item.atlas_coords) 
		world.add_child(item)
		world.box_entities.append(item)
		
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
