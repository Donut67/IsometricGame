extends Structure

var solicitated_boxes = []

@export var item_type : String = "metal_scrap"
@export var solicitated_ammount: int = 1

var order = [
	Vector3( 0,  0, 0), Vector3( 1,  0, 0), Vector3( 1, -1, 0), 
	Vector3( 0, -1, 0), Vector3(-1, -1, 0), Vector3(-1,  0, 0), 
	Vector3(-1,  1, 0), Vector3( 0,  1, 0), Vector3( 1,  1, 0)
]

var boxes_on_top = []

func _ready() -> void:
	super._ready()
	
	structure_type = "scrap_dropper_platform"
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
	
	var spawn_position = Global.screen_to_grid(global_position, 0) + Vector3i(0, 0, 31)
	
	Global.game.world.place_random_box_entity(spawn_position, items)

func is_platform_full() -> bool:
	for box in boxes_on_top:
		# Only count the boxes that are on the ground. 
		
		var real_position = Global.screen_to_grid(global_position, 0)
		var flat_1 = Vector2(real_position.x, real_position.y)
		var flat_2 = Vector2(box.real_position.x, box.real_position.y)
		
		if flat_1.distance_to(flat_2) < 0.75:
			return true
	
	return false

func _on_timer_timeout() -> void:
	if is_platform_full(): return
	
	var types = solicitated_boxes.pop_front()
	
	generate_solicitated_boxes(types)
	prepare_solicitated_boxes()

func _on_top_area_entered(area: Area2D) -> void:
	if boxes_on_top.has(area.owner): return
	
	if area.owner.is_in_group("BoxEntity"):
		boxes_on_top.append(area.owner)

func _on_top_area_exited(area: Area2D) -> void:
	if boxes_on_top.has(area.owner):
		boxes_on_top.erase(area.owner)
