class_name BoxEntity
extends Physics3DIsometric

var grid_position: Vector3i
var time_since_last_fall: float = 0
var atlas_coords: Vector2i

var items: Array = []  # Optional item inside the box
var box_size: int = 5

var prev_position: Vector3

@onready var box_layer: TileMapLayer = $Box
@onready var shadow_layer: TileMapLayer = $Shadow

const box_landing_anim = preload("res://Scenes/Particles/BoxLanding.tscn")

#func _process(delta: float) -> void:
	#$Label.text = str(box_layer.position) + "\n" + str(shadow_layer.position)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	var height = real_position.z
	shadow_layer.position = Global.grid_to_screen(Vector3(real_position.z, 0, -real_position.z))
	
	prev_position = real_position

func set_real_position(real_pos: Vector3, coords: Vector2i):
	real_position = real_pos
	atlas_coords = coords
	
	box_layer.set_cell(Vector2i(-1, 0), 1, coords)
	position = Global.grid_to_screen(real_position)

func set_grid_position(grid_pos: Vector3i, coords: Vector2i):
	grid_position = grid_pos
	real_position = Vector3(grid_position)
	atlas_coords = coords
	
	box_layer.set_cell(Vector2i(-1, 0), 1, coords)
	position = Global.grid_to_screen(grid_pos)

func delete_box(): 
	var cpu_particles = box_landing_anim.instantiate()
	cpu_particles.z_index = z_index
	cpu_particles.global_position = Global.grid_to_screen(grid_position + Vector3i(0, 0, 1))
	
	add_sibling(cpu_particles)
	cpu_particles.global_position = global_position
	cpu_particles.play()
	
	queue_free()

# Puts the item at the end of the list
func put_item(item: Object):
	if items.size() == box_size: return
	
	items.append(item)

func has_space():
	return items.size() < box_size

# Returns the last inserted item and removes it from the list
func get_last_item():
	return get_nth_item(-1)

# Returns the nth inserted item and removes it from the list
func get_nth_item(index: int):
	if index >= items.size(): return null
	
	var item = items[index]
	items.erase(item)
	
	return item
