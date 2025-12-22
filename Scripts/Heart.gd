extends Panel

var value = 0

func set_strenght(_value):
	value = _value
	var stylebox := get_theme_stylebox("panel").duplicate()
	stylebox.border_width_left = value * 3
	add_theme_stylebox_override("panel", stylebox)
