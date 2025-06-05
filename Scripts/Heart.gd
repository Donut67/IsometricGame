extends Panel

var state = "Full"

@onready var empty_heart := preload("res://Assets/Character/Heart/Empty.png")
@onready var half_heart := preload("res://Assets/Character/Heart/Half.png")
@onready var full_heart := preload("res://Assets/Character/Heart/Full.png")


func _process(_delta):
	var stylebox := get_theme_stylebox("panel").duplicate()
	
	if state == "Full": stylebox.border_width_left = 5
	elif state == "Half": stylebox.border_width_left = 2
	else: stylebox.border_width_left = 0
	
	add_theme_stylebox_override("panel", stylebox)
