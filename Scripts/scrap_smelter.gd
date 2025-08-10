extends Node2D

var items = {}
var current_recipe = {}
var game : Node2D

func _ready():
	var shader = load("res://Assets/outline.gdshader")
	$TileMapLayer.material = ShaderMaterial.new()
	$TileMapLayer.material.set("shader", shader)
	$TileMapLayer.material.set("shader_parameter/width", 0)

func _process(_delta: float) -> void:
	$Panel.visible = items.size() > 0
	
	if $Panel.visible:
		var stylebox = $Panel.get_theme_stylebox("panel").duplicate()
		stylebox.border_width_left = ($Timer.wait_time - $Timer.time_left) * 16 / $Timer.wait_time
		$Panel.add_theme_stylebox_override("panel", stylebox)

func add_item(item: Item):
	items[item] = item.item_type
	
	changed_inventory()

func changed_inventory():
	var recipe = Global.find_structure_recipe(items.values(), "scrap_smelter")
	
	if recipe.has("output"):
		if current_recipe != recipe:
			$Timer.wait_time = recipe["time"]
			$Timer.start()
		current_recipe = recipe
	else: $Timer.stop()

func highlight(value: bool):
	$TileMapLayer.material.set("shader_parameter/width", 1 if value else 0)

func _on_timer_timeout() -> void:
	var item = game.item_instance.instantiate()
	item.set_item_type(current_recipe["output"])
	item.real_position = Global.screen_to_grid(global_position, 0)
	game.world.add_child(item)
	game.world.entities.append(item)
	
	var dir_vector = Vector3(1, 0, 1).normalized() + Vector3(randf() * .25 - .125, randf() * .25 - .125, 0)
	item.velocity = Vector3(5, 5, 10) * dir_vector
	
	items = remove_dict_values(items, current_recipe["input"])
	
	current_recipe = {}
	changed_inventory()

func remove_dict_values(first: Dictionary, second: Array) -> Dictionary:
	var result: Dictionary = first.duplicate()
	
	for value in second:
		for key in result.keys():
			if result[key] == value:
				result.erase(key)
				break # only remove one per value
	
	return result
