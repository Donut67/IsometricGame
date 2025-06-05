extends CharacterBody2D

var lives = 3
var previous_dir = Vector2.LEFT
var previous_angle = 0
var _attack = false
var attacked = false
var shot = false
var angle = 26.565051177078

var ARROW = preload("res://Scenes/Objects/Arrow.tscn")

@export var vel = 360
@export var animation_tree : AnimationTree
var playback : AnimationNodeStateMachinePlayback

func _ready():
	playback = animation_tree["parameters/playback"]
	$Sprite2D.texture = Global.current_character

func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if not _attack:
		if Input.is_action_pressed("UP"): dir.y -= 1
		if Input.is_action_pressed("DOWN"): dir.y += 1
		if Input.is_action_pressed("LEFT"): dir.x -= 1
		if Input.is_action_pressed("RIGHT"): dir.x += 1
	
	if Input.is_action_just_pressed("ATTACK") and not _attack: attack()
	if _attack and $AttackTimer.get_time_left() <= 0.1 and not attacked: 
		var scene = ARROW.instantiate()
		scene.set_global_position(position - $ArrowSpawn.get_position())
		get_tree().get_nodes_in_group("Arrows")[0].add_child(scene)
		attacked = true
	
	choose_anim(dir)
	move(dir, delta)


func attack():
	$AttackTimer.start()
	_attack = true
	previous_angle = rad_to_deg(global_position.angle_to_point(get_global_mouse_position()))


func choose_anim(dir):
	if _attack: playback.travel("Attack")
	elif dir == Vector2.ZERO: playback.travel("Idle")
	else: playback.travel("Walk")


func move(dir, delta):
	var anlge_degrees = 0
	
	if dir.x == 1: 
		if dir.y == 0: anlge_degrees = 0
		elif dir.y == -1: anlge_degrees = -angle
		else: anlge_degrees = angle
	elif dir.x == 0:
		if dir.y == 1: anlge_degrees = 90
		elif dir.y == -1: anlge_degrees = 270
	else:
		if dir.y == 1: anlge_degrees = 180 - angle
		elif dir.y == 0: anlge_degrees = 180
		else: anlge_degrees = 180 + angle
	
	if dir != Vector2.ZERO: 
		var vec = Vector2(vel * cos(PI/180*anlge_degrees), vel * sin(PI/180*anlge_degrees))
		vec = vec * delta
		move_and_collide(vec)
	
	move_and_slide()
	update_animation_parameters()
	if dir.x != 0 or dir.y != 0: previous_dir = dir


func update_animation_parameters():
	if previous_dir == Vector2.ZERO: return
	
	animation_tree["parameters/Idle/blend_position"] = previous_dir * Vector2(1, -1)
	animation_tree["parameters/Walk/blend_position"] = previous_dir * Vector2(1, -1)
	animation_tree["parameters/Attack/blend_position"] = previous_dir * Vector2(1, -1)

func take_damage(value):
	lives -= value
	$LiveOverlay.update_lives()


func _on_AttackTimer_timeout():
	_attack = false
	attacked = false
