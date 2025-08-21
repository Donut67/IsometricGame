class_name BasicSmelter
extends ScrapSmelter

func _ready() -> void:
	super._ready()
	
	structure_type = "basic_smelter"

func _process(delta: float) -> void:
	super._process(delta)
	
	if output_inventory != []: 
		var structure = Global.get_structure_at(_get_output_tile_pos())
		
		var item = output_inventory.pop_front()
		structure.add_item(item)
