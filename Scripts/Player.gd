extends CharacterBody2D

var lives = 3
var vel = 300
var previous_dir = Vector2.LEFT
var previous_angle = 0
var _attack = false
var attacked = false
var shot = false
var angle = 26.565051177078

var ARROW = preload("res://Scenes/Objects/Arrow.tscn")

func _physics_process(delta):
	var dir = Vector2.ZERO
	
	if not _attack:
		if Input.is_action_pressed("UP"): dir.y -= 1
		if Input.is_action_pressed("DOWN"): dir.y += 1
		if Input.is_action_pressed("LEFT"): dir.x -= 1
		if Input.is_action_pressed("RIGHT"): dir.x += 1
	
	if Input.is_action_just_pressed("ATTACK") and not _attack: attack()
	if _attack and $AttackTimer.get_time_left() <= 0.4 and not attacked: 
		var scene = ARROW.instantiate()
		scene.set_global_position(position - $AnimatedSprite/ArrowSpawn.get_position())
		get_tree().get_nodes_in_group("Arrows")[0].add_child(scene)
		attacked = true
	
	choose_anim(dir)
	move(dir, delta)


func attack():
	$AttackTimer.start()
	_attack = true
	previous_angle = rad_to_deg(position.angle_to_point(get_global_mouse_position()))


func choose_anim(dir):
	var s = ""
	var anim = ""
	
	if dir.x == 1: $AnimatedSprite.flip_h = true
	elif dir.x == 0: $AnimatedSprite.flip_h = previous_dir.x == 1
	else: $AnimatedSprite.flip_h = false
	
	if dir.y == -1 or dir.y == 0 and previous_dir.y != 1: s = "_n"
	elif dir.y == 1 or dir.y == 0 and previous_dir.y == 1: s = "_s"
	
	if _attack: anim = "Attack"
	elif dir == Vector2.ZERO: anim = "Idle"
	else: anim = "Go"
	
	$AnimatedSprite.play(anim + s)


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
	if dir.x != 0 or dir.y != 0: previous_dir = dir


func take_damage(value):
	lives -= value
	$LiveOverlay.update_lives()


func _on_AttackTimer_timeout():
	_attack = false
	attacked = false
