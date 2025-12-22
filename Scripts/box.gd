class_name BoxEntity
extends Physics3DIsometric

var grid_position: Vector3i
var time_since_last_fall: float = 0
var atlas_coords: Vector2i

var boxes_on_top: Array = []
var items: Array = []  # Optional item inside the box
var box_size: int = 5

var prev_position: Vector3

const box_landing_anim = preload("res://Scenes/Particles/BoxLanding.tscn")

@onready var box_layer: TileMapLayer = $Box
@onready var shadow_layer: TileMapLayer = $Shadow
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var box : TileMapLayer = $TileMapLayer
@onready var timer : Timer = $Timer

var box_position := Vector2i(-1, 0)

var can_move := true

# constants (the face IDs)
const FRONT  = 0
const LEFT   = 1
const BACK   = 2
const RIGHT  = 3
const TOP    = 4
const BOTTOM = 5

# cycles as lists of position names
var cycleA_pos = ["FRONT", "BOTTOM", "BACK", "TOP"]   # A
var cycleB_pos = ["RIGHT", "BOTTOM", "LEFT", "TOP"]   # B
var cycleC_pos = ["FRONT", "LEFT", "BACK", "RIGHT"]   # C

# current mapping position -> face id (start identity)
var pos_to_face = {
	"FRONT": FRONT,
	"LEFT": LEFT,
	"BACK": BACK,
	"RIGHT": RIGHT,
	"TOP": TOP,
	"BOTTOM": BOTTOM
}

# helper: rotate values among a given list of positions by `step`
func rotate_positions(pos_list: Array, step: int) -> Dictionary:
	var positions = pos_to_face.duplicate()
	
	# step can be positive or negative, wrap with modulo
	var n = pos_list.size()
	step = ((step % n) + n) % n
	if step == 0:
		return positions
	
	# copy old values
	var old = {}
	for p in pos_list:
		old[p] = positions[p]
	
	# move value at pos_list[i] -> pos_list[(i+step) % n]
	for i in range(n):
		var from_pos = pos_list[i]
		var to_pos = pos_list[(i + step) % n]
		positions[to_pos] = old[from_pos]
	
	return positions

# helper: returns position where face is at
func get_face_position(positions: Dictionary, face: int) -> int:
	var x = 0
	var found = false
	var keys = positions.keys()
	
	while not found and x < positions.size():
		found = positions[keys[x]] == face
		if not found: x += 1
	
	return x

# Displays the inbetween frame of a movement
# pivot: "FRONT" or "LEFT"
# dir: +1 or -1 (step direction)
func in_between_frame(pivot: String, dir: int) -> void:
	# Normalise dir to +1 or -1
	dir = 1 if dir > 0 else -1
	
	# Get the in-between frame
	var x_pre = get_face_position(pos_to_face, TOP)
	var y_pre = get_face_position(pos_to_face, FRONT)
	
	var next_pos := Vector2i(x_pre, y_pre) * 2
	if pivot == "LEFT" and dir > 0:
		next_pos += Vector2i( 0,  1)
	elif pivot == "FRONT" and dir < 0:
		next_pos += Vector2i( 1,  0)
	else: # equal to -> if pivot == "LEFT" and dir < 0 or pivot == "FRONT" and dir > 0:
		var modified = rotate_positions(cycleA_pos if pivot == "LEFT" else cycleB_pos, dir)
		
		x_pre = get_face_position(modified, TOP)
		y_pre = get_face_position(modified, FRONT)
		
		if pivot == "LEFT":
			next_pos = Vector2i(x_pre * 2, y_pre * 2 + 1)
		elif pivot == "FRONT":
			next_pos = Vector2i(x_pre * 2 + 1, y_pre * 2)
	
	box.set_cell(box_position, 1, next_pos)

# main rotate function
# pivot: "FRONT" or "LEFT"
# dir: +1 or -1 (step direction)
func rotate_over(pivot: String, dir: int) -> void:
	# Normalise dir to +1 or -1
	dir = 1 if dir > 0 else -1
	
	# Always rotate cycle A (all 4 positions)
	pos_to_face = rotate_positions(cycleA_pos if pivot == "LEFT" else cycleB_pos, dir)
	
	var x = get_face_position(pos_to_face, TOP)
	var y = get_face_position(pos_to_face, FRONT)
	
	box.clear()
	box.set_cell(box_position, 1, Vector2i(x, y) * 2)


# twist function, functions as rotate over but with a fixed pivot
# pivot: "FRONT" or "LEFT"
# direction: +1 or -1 (step direction)
func twist(direction) -> void:
	pos_to_face = rotate_positions(cycleC_pos, direction)
	
	var x = get_face_position(pos_to_face, TOP)
	var y = get_face_position(pos_to_face, FRONT)
	
	box.clear()
	box.set_cell(box_position, 1, Vector2i(x, y) * 2)


func move(direction: Vector2i) -> void:
	if not can_move: return
	
	var pivot: String = "LEFT" if direction.x == 0 else "FRONT"
	var dir: int = 1 if pivot == "LEFT" and direction.y > 0 or pivot == "FRONT" and direction.x < 0 else -1
	
	box.clear()
	
	# TEMPORARY: move the box position before setting the in-between frame
	#if pivot == "LEFT" and dir < 0:
		#box_position += direction
	#if pivot == "FRONT" and dir > 0:
		#box_position += direction
	
	in_between_frame(pivot, dir)
	
	# TEMPORARY: move the box position after setting the in-between frame
	#if pivot == "LEFT" and dir < 0:
		#box_position -= direction
	#if pivot == "FRONT" and dir > 0:
		#box_position -= direction
	
	timer.start()
	can_move = false
	timer.timeout.connect(end_animation.bind(pivot, dir))


func end_animation(pivot, dir) -> void:
	rotate_over(pivot, dir)
	can_move = true
	timer.timeout.disconnect(end_animation)


func _ready():
	var shader = load("res://Assets/outline.gdshader")
	box.material = ShaderMaterial.new()
	box.material.set("shader", shader)
	box.material.set("shader_parameter/width", 0)
	
	box.set_cell(Vector2i(-1, 0), 0, Vector2i(4, 0))

func highlight(value: bool):
	box.material.set("shader_parameter/width", 1 if value else 0)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	shadow_layer.position = Global.grid_to_screen(Vector3(real_position.z, 0, -real_position.z))
	
	collision_shape.disabled = real_position.z > 0
	prev_position = real_position

func set_coords(coords: Vector2i):
	atlas_coords = coords
	box_layer.set_cell(Vector2i(-1, 0), 0, coords)

func set_real_position(real_pos: Vector3):
	real_position = real_pos
	
	position = Global.grid_to_screen(real_position)

func set_grid_position(grid_pos: Vector3i):
	grid_position = grid_pos
	real_position = Vector3(grid_position)
	
	position = Global.grid_to_screen(grid_pos)

func delete_box(): 
	var cpu_particles = box_landing_anim.instantiate()
	cpu_particles.z_index = z_index
	
	add_sibling(cpu_particles)
	cpu_particles.global_position = global_position
	cpu_particles.play()
	
	queue_free()

# Puts the item at the end of the list
func put_item(item: Object):
	if not has_space(): return
	
	items.append(item)

func has_space():
	return items.size() < box_size

# Returns the last inserted item and removes it from the list
func get_last_item():
	return get_nth_item(-1)

# Returns the nth inserted item and removes it from the list
func get_nth_item(index: int):
	if items == [] or index >= items.size(): return null
	
	var item = items[index]
	items.erase(item)
	
	return item

func has_box_on_top() -> bool:
	for box in boxes_on_top:
		var flat_1 = Vector2(real_position.x, real_position.y)
		var flat_2 = Vector2(box.real_position.x, box.real_position.y)
		
		if flat_1.distance_to(flat_2) < 0.75: return true
	
	return false

func _on_floor_hit(hit_collision_speed: float) -> void:
	if abs(hit_collision_speed) < 10: return
	
	var cpu_particles = box_landing_anim.instantiate()
	cpu_particles.z_index = z_index
	
	get_parent().add_sibling(cpu_particles)
	cpu_particles.global_position = Global.grid_to_screen(real_position)
	cpu_particles.play()

func _on_top_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("BoxEntity"):
		boxes_on_top.append(area.owner)

func _on_top_area_exited(area: Area2D) -> void:
	if boxes_on_top.has(area.owner):
		boxes_on_top.erase(area.owner)
