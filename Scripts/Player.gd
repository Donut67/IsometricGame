extends CharacterBody2D
class_name Player

var lives = 3
var previous_dir = Vector2.LEFT
var looking_at = Vector2.LEFT
var previous_angle = 0
var _attack = false
var attacked = false
var shot = false
var angle = 26.565051177078
var playback : AnimationNodeStateMachinePlayback

var holding_item: Node = null
var items_in_range: Array = []
var structures_in_range: Array = []

const directions: Dictionary = {
	Vector2( 0,  1): 0,
	Vector2( 1,  1): 1,
	Vector2( 1,  0): 2,
	Vector2( 1, -1): 3,
	Vector2( 0, -1): 4,
	Vector2(-1, -1): 5,
	Vector2(-1,  0): 6,
	Vector2(-1,  1): 7
}

@onready var strenght = $Heart

@export var vel = 128
@export var animation_tree : AnimationTree

func _ready():
	playback = animation_tree["parameters/playback"]
	$Sprite2D.texture = Global.current_character

func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if not _attack:
		dir.x = Input.get_axis("LEFT", "RIGHT")
		dir.y = Input.get_axis("UP", "DOWN")
	
	choose_anim(dir)
	move(dir, delta)

func choose_anim(dir):
	if _attack: playback.travel("Attack")
	elif dir == Vector2.ZERO: playback.travel("Idle")
	else: playback.travel("Walk")

func move(dir, delta):
	move_and_collide(dir.normalized() * vel * delta)
	
	update_animation_parameters()
	if dir.x != 0 or dir.y != 0: previous_dir = dir

func update_animation_parameters():
	if previous_dir == Vector2.ZERO: return
	
	var dir = previous_dir * Vector2(1, -1)
	
	animation_tree["parameters/Idle/blend_position"] = dir
	animation_tree["parameters/Walk/blend_position"] = dir
	animation_tree["parameters/Attack/blend_position"] = dir
	
	$Pointer.position = get_pointer_position()
	$Pointer.z_index = -1
	
	if holding_item != null:
		if holding_item is BoxEntity and previous_dir.length() == 1 and looking_at != previous_dir: 
			var sequence = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
			var steps = (sequence.find(looking_at) - sequence.find(previous_dir)) % 4
			
			holding_item.twist(steps)
		
		var child = directions[dir]
		
		holding_item.real_position = Global.screen_to_grid_f($BoxPositions.get_child(child).position, 0.4)
		holding_item.z_index = 1 if child > 1 and child < 7 else -1
	
	if previous_dir.length() == 1: 
		looking_at = previous_dir

func set_holding_item(item: Node):
	holding_item = item
	
	holding_item.get_parent().remove_child(holding_item)
	holding_item.set_real_position(Vector3.ZERO + Vector3(0, 0, .5))
	
	holding_item.apply_gravity = false
	holding_item.z_ordering = false
	
	add_child(item)

func throw_item():
	#var mouse_pos = Global.screen_to_grid_f(position + get_pointer_position(), 0)
	#var player_pos = Global.screen_to_grid_f(position, 0)
	#var dir_vector = (mouse_pos - player_pos).normalized() + Vector3(0, 0, 1)
	var dir = directions.keys()[(directions[previous_dir] + 1) % directions.size()]
	var dir_vector = Vector3(dir.x, dir.y, 1)
	
	holding_item.apply_gravity = true
	holding_item.z_ordering = true
	
	holding_item.velocity = dir_vector * strenght.value * Vector3(2, 2, 4)# + Vector3(velocity.x, velocity.y, 0) * Vector3(2, 2, 4)
	holding_item.set_real_position(Global.screen_to_grid_f(position, 0) + dir_vector * Vector3(1, 1, 0.25))
	
	strenght.set_strenght(0)
	var item = holding_item
	holding_item = null
	
	return item

func remove_holding_item():
	holding_item.queue_free()
	holding_item = null

func get_pointer_position():
	return previous_dir.normalized() * Vector2(16, 8) + (Vector2.LEFT * 2)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.owner.is_in_group("Item") or area.owner.is_in_group("BoxEntity"):
		items_in_range.append(area.owner)
	elif area.owner.is_in_group("PlacedStructure"):
		structures_in_range.append(area.owner)

func _on_area_2d_area_exited(area: Area2D) -> void:
	if items_in_range.has(area.owner):
		items_in_range.erase(area.owner)
	elif structures_in_range.has(area.owner):
		structures_in_range.erase(area.owner)
