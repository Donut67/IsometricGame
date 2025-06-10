extends Physics3DIsometric

#func _process(delta: float) -> void:
	#print("Velocity: ", velocity, " , Position: ", position)

func set_real_position(real_pos: Vector3):
	real_position = real_pos
	
	position = Global.grid_to_screen(real_position)
