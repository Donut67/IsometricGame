extends Control

func _ready():
	reset_radar()

func reset_radar():
	for i in range(get_child(0).get_child_count()):
		get_child(0).get_child(i).set_modulate(Color(1, 1, 1, 0.5))

func choose_dir(angle):
	if angle < 0: angle = 360 + angle
	if angle >= 22.5 and angle < 67.5: get_child(0).get_child(3).set_modulate(Color(1, 0, 0, 0.5))
	elif angle >= 67.5 and angle < 112.5: get_child(0).get_child(4).set_modulate(Color(1, 0, 0, 0.5))
	elif angle >= 112.5 and angle < 157.5: get_child(0).get_child(5).set_modulate(Color(1, 0, 0, 0.5))
	elif angle >= 157.5 and angle < 205.5: get_child(0).get_child(6).set_modulate(Color(1, 0, 0, 0.5))
	elif angle >= 205.5 and angle < 247.5: get_child(0).get_child(7).set_modulate(Color(1, 0, 0, 0.5))
	elif angle >= 247.5 and angle < 292.5: get_child(0).get_child(0).set_modulate(Color(1, 0, 0, 0.5))
	elif angle >= 292.5 and angle < 337.5: get_child(0).get_child(1).set_modulate(Color(1, 0, 0, 0.5))
	else: get_child(0).get_child(2).set_modulate(Color(1, 0, 0, 0.5))
