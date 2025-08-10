extends CharacterBody2D

var lives = 3
var previous_dir = Vector2.LEFT
var previous_angle = 0
var _attack = false
var attacked = false
var shot = false
var angle = 26.565051177078
var playback : AnimationNodeStateMachinePlayback

var holding_item: Node = null
var items_in_range: Array = []
var structures_in_range: Array = []

const ARROW = preload("res://Scenes/Entities/Arrow.tscn")
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

@export var vel = 360
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
	move_and_collide(dir * vel * delta)
	
	update_animation_parameters()
	if dir.x != 0 or dir.y != 0: previous_dir = dir

func update_animation_parameters():
	if previous_dir == Vector2.ZERO: return
	
	var dir = previous_dir * Vector2(1, -1)
	
	animation_tree["parameters/Idle/blend_position"] = dir
	animation_tree["parameters/Walk/blend_position"] = dir
	animation_tree["parameters/Attack/blend_position"] = dir
	
	if holding_item != null:
		var child = directions[dir]
		
		holding_item.real_position = Global.screen_to_grid_f($BoxPositions.get_child(child).position, 0)
		holding_item.z_index = 0 if child > 1 and child < 7 else -1

func set_holding_item(item: Node):
	holding_item = item
	add_child(item)

func remove_holding_item():
	holding_item.queue_free()
	holding_item = null

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
