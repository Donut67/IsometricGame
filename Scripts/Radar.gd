extends Control

var active_indicators: Array[Sprite2D] = []
var current_index = 0
var arrow_texture = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/8_Direction.png")


func _ready():
	reset_radar()
	clear_unused()


func reset_radar():
	current_index = 0


func clear_unused():
	for i in range(active_indicators.size() - current_index):
		active_indicators[current_index + i].queue_free()


func choose_dir(angle, intersection):
	var indicator
	
	if current_index >= active_indicators.size():
		indicator = create_indicator(intersection)
	else:
		indicator = active_indicators[current_index]
	
	if angle < 0: angle = 360 + angle
	var shifted = fposmod(angle + 22.5, 360.0)  # Shift so 0° maps to sector 0
	var frame = int(floor(shifted / 45.0)) % 8
	
	indicator.frame = frame
	current_index += 1


func create_indicator(intersection):
	var new_indicator := Sprite2D.new()
	
	new_indicator.texture = arrow_texture
	new_indicator.hframes = 8
	new_indicator.global_position = intersection
	new_indicator.scale = Vector2.ONE * 4
	
	add_child(new_indicator)
	active_indicators.append(new_indicator)
	
	return new_indicator
