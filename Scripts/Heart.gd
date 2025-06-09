extends Panel

func set_strenght(value):
	var stylebox := get_theme_stylebox("panel").duplicate()
	stylebox.border_width_left = value * 2
	add_theme_stylebox_override("panel", stylebox)
