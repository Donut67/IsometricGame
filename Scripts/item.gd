extends Physics3DIsometric
class_name Item

var item_type: String = ""

func _ready():
	var shader = load("res://Assets/outline.gdshader")
	$TileMapLayer.material = ShaderMaterial.new()
	$TileMapLayer.material.set("shader", shader)
	$TileMapLayer.material.set("shader_parameter/width", 0)
	
	size = Vector3.ONE * 0.5

func set_item_type(item: String):
	item_type = item
	$TileMapLayer.set_cell(Vector2i(-1, 0), 1, Global.get_item_atlas_coords(item_type))
	
	var type = Global.get_item_group(item_type)
	if type != "":
		remove_from_group("Item")
		
		add_to_group(type)
		add_to_group("Item")

func set_real_position(real_pos: Vector3):
	real_position = real_pos
	
	position = Global.grid_to_screen(real_position)

func highlight(value: bool):
	$TileMapLayer.material.set("shader_parameter/width", 1 if value else 0)
