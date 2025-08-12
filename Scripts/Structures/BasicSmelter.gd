extends ScrapSmelter

func changed_inventory():
	structure = "basic_structure"
	super.changed_inventory()

func set_direction(direction: Vector2i):
	structure_id = 1
	super.set_direction(direction)

func _on_timer_timeout() -> void:
	var item = generate_output()
	
	var dir_vector = Vector3(1, 0, 1).normalized() + Vector3(randf() * .25 - .125, randf() * .25 - .125, 0)
	item.velocity = Vector3(5, 5, 10) * dir_vector
	
	clear_recipe()
