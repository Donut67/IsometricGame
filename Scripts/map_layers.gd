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

const SHADOW_HALF: Vector2i = Vector2i(0, 0)
const SHADOW_FULL: Vector2i = Vector2i(1, 0)
const full_boxes_atlas_coordinates = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 0), Vector2i(0, 1), 
	Vector2i(1, 1), Vector2i(4, 1), Vector2i(0, 4), Vector2i(1, 4), 
	Vector2i(2, 4), Vector2i(0, 0), Vector2i(1, 0), Vector2i(4, 1)
]
const box_entity_instance = preload("res://Scenes/Entities/Box.tscn")

func _ready() -> void:
	#generate_piles()
	#place_shadows()
	place_random_box(Vector3i(0, 0, 0))

func _process(delta: float) -> void:
	for i in box_entities:
		var pos = i.grid_position
		var map_pos = Vector2i(pos.x, pos.y)
		
		if pos.z >= layers.size(): continue
		
		if pos.z < 0:
			place_box(Vector3i(pos.x, pos.y, 0), i.atlas_coords)
			i.queue_free()
			box_entities.erase(i)
		
		if layers[pos.z].get_cell_atlas_coords(Vector2i(pos.x, pos.y)) != Vector2i(-1, -1):
			place_box(pos + Vector3i(0, 0, 1), i.atlas_coords)
			i.queue_free()
			box_entities.erase(i)

func _input(event: InputEvent) -> void:
	pass
	if event.is_action_released("ATTACK"):
		var current_layer = max_height - 1
		var map_position = layers[current_layer].local_to_map(get_local_mouse_position())
		
		print(current_layer, ", ", map_position)
		
		while current_layer >= 0 and layers[current_layer].get_cell_atlas_coords(map_position) == Vector2i(-1, -1):
			current_layer -= 1
			map_position = layers[current_layer].local_to_map(get_local_mouse_position())
		
		var final_position = Vector3i(map_position.x, map_position.y, current_layer)
		if current_layer >= 0: delete_box(final_position)


func generate_piles():
	var used_positions = {}
	
	for i in range(pile_count):
		var center = generate_position()
		while center in used_positions:
			center = generate_position()
		
		used_positions[center] = true
		var height = randi_range(min_height, max_height)
		
		for dz in range(height):
			var radius = max(1, pile_radius - dz + randi() % 2)
			
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					var dist = Vector2(dx, dy).length()
					var chance = randf()
					
					if dist <= radius and chance < 0.85:
						var pos = Vector3i(center.x + dx, center.y + dy, dz)
						
						place_box(pos, full_boxes_atlas_coordinates.pick_random(), false)
						
						if pos.z == 0: used_positions[pos] = true

func generate_position():
	var x = floor(randi() % grid_size.x) - floor(grid_size.x / 2.0)
	var y = floor(randi() % grid_size.y) - floor(grid_size.y / 2.0)
	
	return Vector2i(x, y)

func place_random_box(global_pos: Vector3i, reload_shadows: bool = true):
	place_box(global_pos, full_boxes_atlas_coordinates.pick_random(), reload_shadows)

func place_box(global_pos: Vector3i, coords: Vector2i, reload_shadows: bool = true):
	var pos = Vector2i(global_pos.x, global_pos.y)
	var fall_z = global_pos.z
	
	while fall_z > 0 and layers[fall_z - 1].get_cell_source_id(pos) == -1: fall_z -= 1
	
	global_pos.z = fall_z
	layers[fall_z].set_cell(pos, 1, coords, 0)
	
	heightmap[pos] = max(heightmap.get(pos, -1), fall_z + 1)
	if reload_shadows: place_shadows()

func place_random_box_entity(global_pos: Vector3i):
	place_box_entity(global_pos, full_boxes_atlas_coordinates.pick_random())

func place_box_entity(global_pos: Vector3i, atlas_coords: Vector2i):
	var box = box_entity_instance.instantiate()
	add_child(box)
	box.set_grid_position(global_pos, atlas_coords)
	
	box_entities.append(box)

func place_shadows():
	shadow_layer.clear()
	
	for pos in heightmap.keys():
		var height = heightmap[pos]
		
		for i in range(1, height + 1):
			var shadow_pos = Vector2i(pos.x + i, pos.y)
			if shadow_layer.get_cell_atlas_coords(shadow_pos) == SHADOW_FULL: continue
			shadow_layer.set_cell(shadow_pos, 2, SHADOW_HALF if i == height else SHADOW_FULL, 0)

func delete_box(pos: Vector3i, reload_shadows: bool = true):
	var min_layer = pos.z
	var map_pos = Vector2i(pos.x, pos.y)
	
	layers[min_layer].set_cell(map_pos)
	for layer in range(min_layer + 1, max_height):
		var current_layer = layer - 1
		var atlas_coords = layers[layer].get_cell_atlas_coords(map_pos)
		
		layers[current_layer].set_cell(map_pos, 1, atlas_coords, 0)
	
	heightmap[map_pos] = max(0, heightmap[map_pos] - 1)
	if reload_shadows: place_shadows()


func _on_timer_timeout() -> void:
	place_random_box_entity(Vector3i(0, 0, 31))
