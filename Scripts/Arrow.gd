extends Area2D

@export var vel = 0
@export var damage = 1.5
@onready var angle = get_tree().get_nodes_in_group("player")[0].previous_angle
var vectorVel = Vector2.ZERO
#var angle = 26.565051177078
const Explosion = preload("res://Scenes/Objects/Explosion.tscn")

func _ready():
	rotation_degrees = angle
	vectorVel = Vector2(vel * cos(PI/180*rotation_degrees), vel * sin(PI/180*rotation_degrees))


func _physics_process(delta):
	position += vectorVel * delta


func _on_Timer_timeout():
	queue_free()


func _on_Arrow_body_entered(body):
	if not body.is_in_group("player"): 
		if body.is_in_group("enemy"): body.take_damage(damage)
		var scene = Explosion.instantiate()
		scene.get_node(".").set_emitting(true)
		scene.set_position(get_position())
		get_tree().get_nodes_in_group("Explosions")[0].add_child(scene)
		queue_free()
