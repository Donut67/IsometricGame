class_name ScrapSmelter
extends ContainerStructure

var current_recipe = {}
var game : Node2D
var structure = "scrap_smelter"
var structure_id = 0
var directions = {
	Vector2i( 0, -1): Vector2i(0, 0),
	Vector2i( 1,  0): Vector2i(1, 0),
	Vector2i( 0,  1): Vector2i(2, 0),
	Vector2i(-1,  0): Vector2i(3, 0),
}

func _process(_delta: float) -> void:
	$Panel.visible = items.size() > 0
	
	if $Panel.visible:
		var stylebox = $Panel.get_theme_stylebox("panel").duplicate()
		stylebox.border_width_left = ($Timer.wait_time - $Timer.time_left) * 16 / $Timer.wait_time
		$Panel.add_theme_stylebox_override("panel", stylebox)

func set_direction(direction: Vector2i):
	$TileMapLayer.set_cell(directions[direction] + Vector2i(0, structure_id))

func changed_inventory():
	var dict = {}
	for item in items.values():
		if dict.has(item): dict[item] += 1
		else: dict[item] = 1
	
	var text = ""
	for key in dict.keys():
		text += key + " [" + str(dict[key]) + "]\n"
	
	$Label.text = text
	
	var recipe = Global.find_structure_recipe(items.values(), structure)
	
	if recipe.has("output"):
		if current_recipe != recipe:
			$Timer.wait_time = recipe["time"]
			$Timer.start()
		current_recipe = recipe
	else: $Timer.stop()

func _on_timer_timeout() -> void:
	var item = generate_output()
	
	var dir_vector = Vector3(1, 0, 1).normalized() + Vector3(randf() * .25 - .125, randf() * .25 - .125, 0)
	item.velocity = Vector3(5, 5, 10) * dir_vector
	
	clear_recipe()

func generate_output():
	var item = game.item_instance.instantiate()
	item.set_item_type(current_recipe["output"])
	item.real_position = Global.screen_to_grid(global_position, 0)
	
	game.world.add_child(item)
	game.world.entities.append(item)
	
	return item

func clear_recipe():
	items = remove_dict_values(items, current_recipe["input"])
	current_recipe = {}
	changed_inventory()
