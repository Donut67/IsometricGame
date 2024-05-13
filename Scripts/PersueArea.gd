extends Area2D

@onready var player = get_tree().get_nodes_in_group("player")[0]
var can_persue = false

func _process(delta):
	can_persue = overlaps_body(player) and get_parent().state == "Idle"

