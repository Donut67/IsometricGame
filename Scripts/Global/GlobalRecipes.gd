extends Node

# Items
## { String(item_name): Array([AtlasCoordinates, Type]) }
## Type is a string either "", "Tool" or "Structure"
var items_atlas_coords: Dictionary = {
	"metal_scrap": [Vector2i(0, 0), ""],
	"plastic_chunk": [Vector2i(1, 0), ""],
	"carbon_dust": [Vector2i(2, 0), ""],
	
	"metal_scrap_bar": [Vector2i(0, 1), ""],
	"plastic_bar": [Vector2i(1, 1), ""],
	"plastic_handle": [Vector2i(2, 1), ""],
	"scrap_hammer": [Vector2i(3, 1), "Tool"],
	"metal_scrap_panel": [Vector2i(4, 1), ""],
	"scrap_trowel": [Vector2i(5, 1), "Tool"],
	"scrap_structure": [Vector2i(6, 1), ""],
	"scrap_smelting_structure": [Vector2i(7, 1), ""],
	"scrap_smelter": [Vector2i(8, 1), "Structure"],
	"scrap_dropper_platform": [Vector2i(9, 1), "Structure"],
	
	"raw_metal": [Vector2i(0, 2), ""],
	"metal_bar": [Vector2i(1, 2), ""],
	"metal_panel": [Vector2i(2, 2), ""],
	"metal_structure": [Vector2i(3, 2), ""],
	"metal_smelting_structure": [Vector2i(4, 2), ""],
	"basic_smelter": [Vector2i(5, 2), "Structure"],
	"metal_hammer": [Vector2i(6, 2), "Tool"],
	"metal_block": [Vector2i(7, 2), ""],
	"metal_cast": [Vector2i(8, 2), "Structure"],
	"basic_press": [Vector2i(9, 2), "Structure"],
	"basic_tube_mill": [Vector2i(10, 2), "Structure"],
}

# Recipes
## { "input": Array(String(item_name)), "output": String(item_name), "tool": Array(String(tool_name))}
## "output" is optional, that meas that the recipes is done by hitting an item with another
var recipe_list: Array = [
	{"input": ["plastic_chunk", "plastic_chunk"], "output": "plastic_bar"},
	{"input": ["plastic_bar", "metal_scrap"], "output": "plastic_handle"},
	{"input": ["metal_scrap", "metal_scrap"], "output": "metal_scrap_bar"},
	{"input": ["plastic_handle", "metal_scrap_bar"], "output": "scrap_hammer"},
	
	{"input": ["metal_scrap_bar"], "output": "metal_scrap_panel", "tool": ["scrap_hammer"]},
	{"input": ["plastic_handle", "metal_scrap_panel"], "output": "scrap_trowel"},
	{"input": ["metal_scrap_panel", "metal_scrap_panel", "metal_scrap_panel", "metal_scrap_panel"], "output": "scrap_structure", "tool": ["scrap_hammer"]}, 
	{"input": ["scrap_structure", "metal_scrap_bar", "carbon_dust"], "output": "scrap_smelting_structure", "tool": ["scrap_hammer"]},
	{"input": ["scrap_smelting_structure", "metal_scrap_panel"], "output": "scrap_smelter"},
	{"input": ["scrap_structure", "plastic_bar", "metal_scrap_panel"], "output": "scrap_dropper_platform", "tool": ["scrap_hammer"]},
	
	{"input": ["raw_metal", "raw_metal"], "output": "metal_bar"},
	{"input": ["metal_bar"], "output": "metal_panel", "tool": ["scrap_hammer", "metal_hammer"]},
	{"input": ["plastic_handle", "metal_bar"], "output": "metal_hammer"},
	
	{"input": ["metal_panel", "metal_panel", "metal_panel", "metal_panel"], "output": "metal_structure", "tool": ["scrap_hammer", "metal_hammer"]}, 
	{"input": ["metal_structure", "metal_bar", "carbon_dust"], "output": "metal_smelting_structure", "tool": ["scrap_hammer", "metal_hammer"]},
	{"input": ["metal_smelting_structure", "metal_panel"], "output": "basic_smelter"},
	
	{"input": ["metal_panel", "metal_panel"], "output": "metal_block", "tool": ["metal_hammer"]},
	
	{"input": ["metal_block"], "output": "metal_cast", "tool": ["metal_hammer"]},
	{"input": ["metal_structure", "metal_block", "metal_bar"], "output": "basic_press", "tool": ["scrap_hammer", "metal_hammer"]},
	{"input": ["metal_structure", "metal_block", "metal_panel"], "output": "basic_tube_mill", "tool": ["scrap_hammer", "metal_hammer"]},
]

# Structures
## { Key(item_type): Array([atlas_coords, PackagedScene]) }
var structure_atlas_coords: Dictionary = {
	"scrap_smelter": [Vector2i(1, 0), preload("res://Scenes/Structures/ScrapSmelter.tscn"), ["metal_scrap", "carbon_dust"]],
	"scrap_dropper_platform": [Vector2i(1, 1), preload("res://Scenes/Structures/ScrapDropperPlatform.tscn"), []],
	"basic_smelter": [Vector2i(1, 2), preload("res://Scenes/Structures/BasicSmelter.tscn"), ["metal_scrap", "carbon_dust"]],
	"metal_cast": [Vector2i(1, 3), preload("res://Scenes/Structures/MetalCast.tscn"), []],
	"basic_press": [Vector2i(1, 4), preload("res://Scenes/Structures/BasicPress.tscn"), ["metal_scrap_bar", "metal_bar"]],
	"basic_tube_mill": [Vector2i(1, 5), preload("res://Scenes/Structures/MetalCast.tscn"), []],
	"scrap_dropper": [Vector2i(1, 3), preload("res://Scenes/Structures/ScrapDropper.tscn"), []],
}

# Structure recipes
## { Key(structure_name): Array(recipe) }
## Each recipe has an extra parameter, time, but now does not have the tool one
var structure_recipe_list: Dictionary = {
	"scrap_smelter": [
		{"input": ["metal_scrap", "carbon_dust", "carbon_dust"], "output": "raw_metal", "time": 5}, 
	],
	"basic_smelter": [
		{"input": ["metal_scrap", "carbon_dust"], "output": "raw_metal", "time": 4}, 
	],
	"basic_press": [
		{"input": ["metal_scrap_bar"], "output": "metal_scrap_panel", "time": 4}, 
		{"input": ["metal_bar"], "output": "metal_panel", "time": 4}, 
	]
}
