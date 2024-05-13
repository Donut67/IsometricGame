extends Area2D

@onready var player = get_tree().get_nodes_in_group("player")[0]
var can_attack = false

func _process(delta):
	can_attack = overlaps_body(player)
