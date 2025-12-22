extends Node2D

@onready var box : TileMapLayer = $TileMapLayer
@onready var timer : Timer = $Timer

var box_position := Vector2i(-1, -1)

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

# current mapping position -> face id (start identity)
var pos_to_face = {
	"FRONT": FRONT,
	"LEFT": LEFT,
	"BACK": BACK,
	"RIGHT": RIGHT,
	"TOP": TOP,
	"BOTTOM": BOTTOM
}

func _ready() -> void:
	box.set_cell(Vector2i(-1, -1), 1, Vector2i(8, 0))

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


func move(direction: Vector2i) -> void:
	if not can_move: return
	
	var pivot: String = "LEFT" if direction.x == 0 else "FRONT"
	var dir: int = 1 if pivot == "LEFT" and direction.y > 0 or pivot == "FRONT" and direction.x < 0 else -1
	
	box.clear()
	
	# TEMPORARY: move the box position before setting the in-between frame
	if pivot == "LEFT" and dir < 0:
		box_position += direction
	if pivot == "FRONT" and dir > 0:
		box_position += direction
	
	in_between_frame(pivot, dir)
	
	# TEMPORARY: move the box position after setting the in-between frame
	if pivot == "LEFT" and dir < 0:
		box_position -= direction
	if pivot == "FRONT" and dir > 0:
		box_position -= direction
	
	timer.start()
	can_move = false
	timer.timeout.connect(end_animation.bind(pivot, dir))


func end_animation(pivot, dir) -> void:
	rotate_over(pivot, dir)
	can_move = true
	timer.timeout.disconnect(end_animation)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		move(Vector2i( 0,  1))  # Vector2i( 0,  1)
	if event.is_action_pressed("ui_up"):
		move(Vector2i( 0, -1))  # Vector2i( 0, -1)
	if event.is_action_pressed("ui_left"):
		move(Vector2i(-1,  0)) # Vector2i(-1,  0)
	if event.is_action_pressed("ui_right"):
		move(Vector2i( 1,  0)) # Vector2i( 1,  0)
