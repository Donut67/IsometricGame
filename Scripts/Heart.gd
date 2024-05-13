extends Sprite2D

var state = "Full"

@onready var empty_heart := preload("res://Character/Heart/Empty.png")
@onready var half_heart := preload("res://Character/Heart/Half.png")
@onready var full_heart := preload("res://Character/Heart/Full.png")


func _process(delta):
	if state == "Full": texture = full_heart
	elif state == "Half": texture = half_heart
	else: texture = empty_heart
