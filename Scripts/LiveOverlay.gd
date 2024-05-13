extends Node2D

var heart = preload("res://Scenes/Objects/Heart.tscn")
@onready var max_lives = get_parent().lives
var lives = 0

func _ready():
	lives = max_lives
	for i in range(max_lives):
		var scene = heart.instantiate()
		scene.set_position(Vector2(i + i * 25, 0))
		call_deferred("add_child", scene)


func update_lives():
	lives = get_parent().lives
	for i in range(max_lives): get_child(i).state = "Empty"
	for i in range(int(lives)):  get_child(i).state = "Full"
	if lives > int(lives) and int(lives) < int(lives) + 1: get_child(int(lives)).state = "Half"
