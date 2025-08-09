extends Node2D

var items = {}
var current_recipe = {}

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
			$Timer.start()
			$Timer.wait_time = recipe["time"]
		
		current_recipe = recipe
	else: $Timer.stop()

func _on_timer_timeout() -> void:
	print(current_recipe["output"])
	
	changed_inventory()
