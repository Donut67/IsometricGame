extends Node

const TILE_SIZE := preload("res://TileSets/box_tileset.tres").tile_size  # Width x Height of one tile
const LAYER_HEIGHT := 9  # Vertical pixels per Z-layer (stack height)

const TITLE = preload("res://Scenes/Game/TitleScreen.tscn")
const GAME = preload("res://Scenes/Game/InGame.tscn")
const END = preload("res://Scenes/Game/EndScreen.tscn")

const box_landing_anim = preload("res://Scenes/Particles/BoxLanding.tscn")

const BASE_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Base_Character.png")
const BOY_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Boy_Character.png")
const GIRL_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Girl_Character.png")

var current_character = BASE_CHARACTER_TEXTURE
var max_round = 0
var current_scene = null

# Items
const items_atlas_coords: Dictionary = {
	"metal_scrap": [Vector2i(0, 0), ""],
	"plastic_chunk": [Vector2i(1, 0), ""],
	"carbon_dust": [Vector2i(2, 0), ""],
	"metal_scrap_bar": [Vector2i(0, 1), ""],
	"plastic_bar": [Vector2i(1, 1), ""],
	"platic_handle": [Vector2i(2, 1), ""],
	"scrap_hammer": [Vector2i(3, 1), "Tool"],
	"metal_scrap_panel": [Vector2i(4, 1), ""],
	"scrap_structure": [Vector2i(5, 1), ""],
	"scrap_smelting_structure": [Vector2i(6, 1), ""],
	"scrap_smelter": [Vector2i(7, 1), "Structure"],
	"raw_metal": [Vector2i(0, 2), ""],
	"metal_bar": [Vector2i(1, 2), ""],
	"metal_panel": [Vector2i(2, 2), ""],
	"metal_structure": [Vector2i(3, 2), ""],
	"metal_smelting_structure": [Vector2i(4, 2), ""],
	"basic_smelter": [Vector2i(5, 2), "Structure"],
	"metal_hammer": [Vector2i(6, 2), "Tool"],
	"metal_block": [Vector2i(7, 2), ""],
	"metal_cast": [Vector2i(8, 2), "Structure"],
}

var recipe_list: Array = [
	{"input": ["plastic_chunk", "plastic_chunk"], "output": "plastic_bar"},
	{"input": ["plastic_bar", "metal_scrap"], "output": "platic_handle"},
	{"input": ["metal_scrap", "metal_scrap"], "output": "metal_scrap_bar"},
	{"input": ["platic_handle", "metal_scrap_bar"], "output": "scrap_hammer"},
	
	{"input": ["metal_scrap_bar"], "output": "metal_scrap_panel", "tool": "scrap_hammer"},
	{"input": ["metal_scrap_panel", "metal_scrap_panel", "metal_scrap_panel", "metal_scrap_panel"], "output": "scrap_structure", "tool": "scrap_hammer"}, 
	{"input": ["scrap_structure", "metal_scrap_bar", "carbon_dust"], "output": "scrap_smelting_structure", "tool": "scrap_hammer"},
	{"input": ["scrap_smelting_structure", "metal_scrap_panel"], "output": "scrap_smelter"},
	
	{"input": ["raw_metal", "raw_metal"], "output": "metal_bar"},
	{"input": ["metal_bar"], "output": "metal_panel", "tool": "scrap_hammer"},
	{"input": ["metal_panel", "metal_panel", "metal_panel", "metal_panel"], "output": "metal_structure", "tool": "scrap_hammer"}, 
	{"input": ["metal_structure", "metal_bar", "carbon_dust"], "output": "metal_smelting_structure", "tool": "scrap_hammer"},
	{"input": ["metal_smelting_structure", "metal_panel"], "output": "basic_smelter"},
	
	{"input": ["platic_handle", "metal_bar"], "output": "metal_hammer"},
	
	{"input": ["metal_panel", "metal_panel"], "output": "metal_block", "tool": "metal_hammer"},
	{"input": ["metal_block"], "output": "metal_cast", "tool": "metal_hammer"},
]

# Structures
# Key(item_type): Array([atlas_coords, PackagedScene])
const structure_atlas_coords: Dictionary = {
	"scrap_smelter": [Vector2i(1, 0), preload("res://Scenes/Structures/ScrapSmelter.tscn")],
	"basic_smelter": [Vector2i(1, 1), preload("res://Scenes/Structures/BasicSmelter.tscn")],
	"metal_cast": [Vector2i(1, 2), preload("res://Scenes/Structures/MetalCast.tscn")],
}

var structure_recipe_list: Dictionary = {
	"scrap_smelter": [
		{"input": ["metal_scrap", "carbon_dust", "carbon_dust"], "output": "raw_metal", "time": 5}, 
	],
	"basic_smelter": [
		{"input": ["metal_scrap", "carbon_dust"], "output": "raw_metal", "time": 4}, 
	],
}

# Items functions
func get_item_atlas_coords(item_type: String) -> Vector2i:
	return items_atlas_coords[item_type][0]

func get_item_group(item_type: String) -> String:
	return items_atlas_coords[item_type][1]

# Structure functions
func get_structure_atlas_coords(item_type: String) -> Vector2i:
	return structure_atlas_coords[item_type][0]

func get_structure_scene(item_type: String) -> PackedScene:
	return structure_atlas_coords[item_type][1]

func get_recipe_key(items: Array) -> String:
	items.sort()
	return ",".join(items)

func find_recipe(items: Array[String], tool: String = "") -> Dictionary:
	if tool != "": return find_advanced_recipe(items, tool)
	
	for recipe in recipe_list:
		var this = get_recipe_key(recipe["input"])
		var that = get_recipe_key(items)
		
		if this == that: return recipe
	
	return {}

func find_advanced_recipe(items: Array[String], tool: String) -> Dictionary:
	var best_recipe = {}
	var best_match_count = -1
	
	for recipe in recipe_list:
		# Check tool requirement
		if not "tool" in recipe or "tool" in recipe and recipe["tool"] != tool:
			continue
		
		var required_inputs = recipe["input"]
		var matched_inputs = []
		var available_copy = items.duplicate()
		
		# Try to match recipe inputs against available items (respecting item count)
		for req_item in required_inputs:
			if req_item in available_copy:
				matched_inputs.append(req_item)
				available_copy.erase(req_item)  # Remove matched item to avoid double counting
		
		var match_count = matched_inputs.size()
		
		# Only consider recipes that have fully matched their inputs
		if match_count == required_inputs.size() and match_count > best_match_count:
			best_match_count = match_count
			best_recipe = recipe
	
	return best_recipe

func find_structure_recipe(items: Array, structure: String) -> Dictionary:
	var best_recipe = {}
	var best_match_count = -1
	
	for recipe in structure_recipe_list[structure]:
		var required_inputs = recipe["input"]
		var matched_inputs = []
		var available_copy = items.duplicate()
		
		# Try to match recipe inputs against available items (respecting item count)
		for req_item in required_inputs:
			if req_item in available_copy:
				matched_inputs.append(req_item)
				available_copy.erase(req_item)  # Remove matched item to avoid double counting
		
		var match_count = matched_inputs.size()
		
		# Only consider recipes that have fully matched their inputs
		if match_count == required_inputs.size() and match_count > best_match_count:
			best_match_count = match_count
			best_recipe = recipe
	
	return best_recipe

func play_landing_animation(position):
	var cpu_particles = box_landing_anim.instantiate()
	
	add_sibling(cpu_particles)
	cpu_particles.global_position = position
	cpu_particles.play()

func _goto_scene(scene):
	call_deferred("_deferrend_goto_scene", scene)

func _deferrend_goto_scene(path):
	var scene = TITLE if path == "title" else GAME if path == "game" else END
	current_scene.free()
	current_scene = scene.instantiate()
	get_tree().get_root().add_child(current_scene)
	#get_tree().set_current_scene(current_scene)

func _change_character(tab: int): 
	current_character = BASE_CHARACTER_TEXTURE if tab == 0 else BOY_CHARACTER_TEXTURE if tab == 1 else GIRL_CHARACTER_TEXTURE

# Convert grid position (Vector3i) → screen (Vector2)
func grid_to_screen(grid_pos: Vector3) -> Vector2:
	var iso_x = (grid_pos.x - grid_pos.y) * TILE_SIZE.x / 2
	var iso_y = (grid_pos.x + grid_pos.y) * TILE_SIZE.y / 2 - grid_pos.z * LAYER_HEIGHT
	return Vector2(iso_x, iso_y)

# Convert screen position (Vector2) + z → grid position (Vector3i)
func screen_to_grid(screen_pos: Vector2, z: int) -> Vector3i:
	# Remove vertical layer offset
	var adj_y = screen_pos.y + z * LAYER_HEIGHT

	# Invert isometric projection
	var x = ((screen_pos.x / (TILE_SIZE.x / 2.0)) + (adj_y / (TILE_SIZE.y / 2.0))) / 2
	var y = ((adj_y / (TILE_SIZE.y / 2.0)) - (screen_pos.x / (TILE_SIZE.x / 2.0))) / 2

	return Vector3i(round(x), round(y), z)

# Convert screen position (Vector2) + z → grid position (Vector3i)
func screen_to_grid_f(screen_pos: Vector2, z: float) -> Vector3:
	# Remove vertical layer offset
	var adj_y = screen_pos.y + z * LAYER_HEIGHT

	# Invert isometric projection
	var x = ((screen_pos.x / (TILE_SIZE.x / 2.0)) + (adj_y / (TILE_SIZE.y / 2.0))) / 2
	var y = ((adj_y / (TILE_SIZE.y / 2.0)) - (screen_pos.x / (TILE_SIZE.x / 2.0))) / 2

	return Vector3(x, y, z)

func intersect(array1, array2):
	var intersection = []
	
	for item in array1:
		if array2.has(item):
			intersection.append(item)
	
	return intersection
