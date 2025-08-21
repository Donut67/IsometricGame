extends Structure

var solicitated_boxes = []
var solicitated_ammount: int = 1
var item_type : String = "metal_scrap"

func _ready() -> void:
	super._ready()
	
	structure_type = "scrap_dropper_platform"
	prepare_solicitated_boxes()

func _on_timer_timeout() -> void:
	if not is_platform_built() or is_platform_full(): return
	
	var types = solicitated_boxes.pop_front()
	
	generate_solicitated_boxes(types)
	prepare_solicitated_boxes()

func prepare_solicitated_boxes():
	var items = []
	
	for i in range(solicitated_ammount): 
		items.append(item_type)
	
	solicitated_boxes.append(items)

func generate_solicitated_boxes(item_types: Array):
	var items = []
	
	for type in item_types:
		items.append(Global.create_item(type))
	
	Global.game.world.place_random_box_entity(Global.screen_to_grid(global_position, 0) + Vector3i(0, 0, 31), items)

func is_platform_built() -> bool:
	var platform_position = Global.screen_to_grid(global_position, 0) - Vector3i(1, 1, 0)
	
	for x in range(3):
		for y in range(3):
			var structure = Global.get_structure_at(platform_position + Vector3i(x, y, 0))
			
			if structure == null or structure.structure_type != structure_type:
				return false
	
	return true

func is_platform_full() -> bool:
	var platform_position = Global.screen_to_grid(global_position, 0)
	var _directions = [Vector3i(1, 1, 0), Vector3i(1, -1, 0), Vector3i(-1, 1, 0), Vector3i(-1, -1, 0)]
	
	for dir in _directions:
		if not Global.has_box(platform_position + dir): return false
	
	return true
