extends Node2D
class_name ContainerStructure

var items = {}
var size : int

func _ready():
	var shader = load("res://Assets/outline.gdshader")
	$TileMapLayer.material = ShaderMaterial.new()
	$TileMapLayer.material.set("shader", shader)
	$TileMapLayer.material.set("shader_parameter/width", 0)
	
func highlight(value: bool):
	$TileMapLayer.material.set("shader_parameter/width", 1 if value else 0)

func add_item(item: Item) -> bool:
	if items.size() == size - 1: return false
	
	items[item] = item.item_type
	changed_inventory()
	
	return true

func changed_inventory(): 
	pass

func remove_dict_values(first: Dictionary, second: Array) -> Dictionary:
	var result: Dictionary = first.duplicate()
	
	for value in second:
		for key in result.keys():
			if result[key] == value:
				result.erase(key)
				break # only remove one per value
	
	return result
