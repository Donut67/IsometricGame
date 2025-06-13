extends Physics3DIsometric

var item_type: String = ""

func _ready():
	var material = load("res://Assets/outline.gdshader")
	$TileMapLayer.material = ShaderMaterial.new()
	$TileMapLayer.material.set("shader", material)
	$TileMapLayer.material.set("shader_parameter/width", 0)

func set_item_type(item: String):
	item_type = item
	$TileMapLayer.set_cell(Vector2i.ZERO, 1, Global.items_atlas_coords[item_type])
	#$Label.text = item_type

func set_real_position(real_pos: Vector3):
	real_position = real_pos
	
	position = Global.grid_to_screen(real_position)

func highlight(value: bool):
	$TileMapLayer.material.set("shader_parameter/width", 1 if value else 0)
