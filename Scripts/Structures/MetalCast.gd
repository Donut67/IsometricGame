extends ContainerStructure
class_name MetalCast

var liquid
var game : Node2D
var current_recipe = {}

func _init() -> void:
	size = 1

func add_item(item: Item) -> bool:
	if not $Timer.is_stopped(): return false
	
	return super.add_item(item)

func changed_inventory():
	
	
	var recipe = Global.find_structure_recipe(liquid, "metal_cast")
	
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
