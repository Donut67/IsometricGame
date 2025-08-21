extends Structure

var solicitated_boxes = []
var item_type : String = "metal_scrap"

func _ready() -> void:
	super._ready()
	
	structure_type = "scrap_dropper"
	solicitated_boxes.append([item_type, item_type, item_type, item_type])

func _on_timer_timeout() -> void:
	if is_platform_full(): return
	
	var types = solicitated_boxes.pop_front()
	var items = []
	
	for type in types:
		items.append(Global.create_item(type))
	
	Global.game.world.place_random_box_entity(Global.screen_to_grid(global_position, 0) + Vector3i(1, 1, 31), items)
	
	solicitated_boxes.append([item_type, item_type, item_type, item_type])

func is_platform_full() -> bool:
	var platform_position = Global.screen_to_grid(global_position, 0) + Vector3i(1, 1, 0)
	var _directions = [Vector3i(1, 1, 0), Vector3i(1, -1, 0), Vector3i(-1, 1, 0), Vector3i(-1, -1, 0)]
	
	for dir in _directions:
		if not Global.has_box(platform_position + dir): return false
	
	return true
