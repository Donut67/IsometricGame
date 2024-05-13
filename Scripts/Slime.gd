extends CharacterBody2D

@export var damage = 10
@export var jump_speed = 3
@export var lives = 3
var state = "Idle"
var vel = Vector2.ZERO
const Spawn = preload("res://Scenes/Objects/SpawnParticles.tscn")

@onready var player = get_tree().get_nodes_in_group("player")[0]

func _ready():
	var scene = Spawn.instantiate()
	scene.get_node(".").set_emitting(true)
	scene.set_position(get_position() + Vector2(10, 0))
	get_tree().get_nodes_in_group("Explosions")[0].add_child(scene)

func _physics_process(delta):
	position += vel * delta
	
	if $HitBoxArea.can_attack and state == "Idle": attack()
	elif $PersueArea.can_persue: _on_PersueArea_overlay(player)
	
	if state == "Jumping": $AnimatedSprite.play("Jump")
	elif state == "Attacking": $AnimatedSprite.play("Attack")
	else: $AnimatedSprite.play("Idle")


func _on_PersueArea_overlay(body):
	$RayCast2D.target_position = body.get_global_position() - get_global_position()
	$RayCast2D.force_raycast_update()
	if $RayCast2D.is_colliding():
		if $RayCast2D.get_collider().is_in_group("player") or $RayCast2D.get_collider().is_in_group("enemy"): jump(body.get_position())


func attack():
	state = "Attacking"
	$AttackDuration.start()
	$ToAttack.start()


func jump(pos):
	state = "Jumping"
	var dist = get_position().distance_to(pos)
	var aux_speed = jump_speed if dist > 150 else dist - 40
	vel = pos - get_position()
	vel = vel.normalized() * aux_speed
	$JumpDuration.start()


func _on_JumpDuration_timeout():
	vel = Vector2.ZERO
	state = "Jump cooldown"
	$JumpCooldown.start()


func _on_JumpCooldown_timeout():
	state = "Idle"


func _on_AttackDuration_timeout():
	state = "Attack cooldown"
	$AttackCooldown.start()


func _on_AttackCooldown_timeout():
	state = "Idle"


func _on_ToAttack_timeout():
	if $HitBoxArea.can_attack: player.take_damage(damage)


func take_damage(value):
	lives -= value
	if lives <= 0: 
		queue_free()
		get_tree().get_nodes_in_group("Timer")[0]._add_time(5)
		get_tree().get_nodes_in_group("EnemyC")[0]._kill_enemy()
	$LiveOverlay.update_lives()


func _on_AttackArea_body_entered(body):
	if body.is_in_group("arrow"): 
		take_damage(body.damage)
		body.queue_free()


