extends Node

const TILE_SIZE := preload("res://TileSets/box_tileset.tres").tile_size  # Width x Height of one tile
const LAYER_HEIGHT := 9  # Vertical pixels per Z-layer (stack height)

const TITLE = preload("res://Scenes/Game/TitleScreen.tscn")
const GAME = preload("res://Scenes/Game/InGame.tscn")
const END = preload("res://Scenes/Game/EndScreen.tscn")

const box_landing_anim = preload("res://Scenes/Particles/BoxLanding.tscn")
const item_instance = preload("res://Scenes/Objects/Item.tscn")

const BASE_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Base_Character.png")
const BOY_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Boy_Character.png")
const GIRL_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Girl_Character.png")

var current_character = BASE_CHARACTER_TEXTURE
var max_round = 0
var current_scene = null

var game: Node2D

func _ready() -> void:
	game = get_tree().root.get_node("Game")

# Items functions
func get_item_atlas_coords(item_type: String) -> Vector2i:
	return GlobalRecipes.items_atlas_coords[item_type][0]

func get_item_group(item_type: String) -> String:
	return GlobalRecipes.items_atlas_coords[item_type][1]

# Structure functions
func get_structure_atlas_coords(item_type: String) -> Vector2i:
	return GlobalRecipes.structure_atlas_coords[item_type][0]

func get_structure_scene(item_type: String) -> PackedScene:
	return GlobalRecipes.structure_atlas_coords[item_type][1]

func add_solicitated_box(box: Dictionary):
	game.solicitated_boxes.append(box)

func get_recipe_key(items: Array) -> String:
	items.sort()
	return ",".join(items)

func find_recipe(items: Array[String], tool: String = "") -> Dictionary:
	if tool != "": return find_advanced_recipe(items, tool)
	
	for recipe in GlobalRecipes.recipe_list:
		var this = get_recipe_key(recipe["input"])
		var that = get_recipe_key(items)
		
		if this == that: return recipe
	
	return {}

func find_advanced_recipe(items: Array[String], tool: String) -> Dictionary:
	var best_recipe = {}
	var best_match_count = -1
	
	for recipe in GlobalRecipes.recipe_list:
		# Check tool requirement
		if not "tool" in recipe or "tool" in recipe and not recipe["tool"].has(tool):
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
	if not structure in GlobalRecipes.structure_recipe_list: return {}
	
	var best_recipe = {}
	var best_match_count = -1
	
	for recipe in GlobalRecipes.structure_recipe_list[structure]:
		if not "input" in recipe: continue
		
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

func get_alternative_pattern(recipe: Dictionary) -> Dictionary:
	return rotate_pattern(recipe, Vector3i.UP)

# Pattern is assumed to be orientated to Vector3i.RIGHT, original
func rotate_pattern(recipe: Dictionary, direction: Vector3i) -> Dictionary:
	var rotated = recipe.duplicate()
	var pattern = recipe["pattern"]
	var size    = recipe["size"]
	
	rotated["pattern"] = {}
	
	# Rotate positions
	for position in pattern.keys():
		var type = pattern[position]
		
		if direction == Vector3i.RIGHT:
			rotated["pattern"][position] = type
		elif direction == Vector3i.UP:
			rotated["pattern"][Vector3i(-position.y + (size.y - 1), position.x, position.z)] = type
	
	# Rotate size
	rotated["size"] = size if direction == Vector3i.RIGHT else Vector3i(size.y, size.x, size.z)
	
	return rotated

func check_pattern(origin: Vector3i, pattern: Dictionary) -> bool:
	for position in pattern.keys():
		var required = pattern[position]
		var pos = origin + position
		var structure = get_structure_at(pos)
		
		if structure == null or structure.structure_type != required:
			return false
	
	return true

func get_structure_at(position) -> Structure:
	return game.world.structure_data[position] if has_structure(position) else null

func remove_structure_at(position): 
	game.world.remove_structure(position)

# position should already be a 'real_position' coordinate
func create_item(item_type: String, position: Vector3 = Vector3.INF) -> Node:
	var item = item_instance.instantiate()
	item.set_item_type(item_type)
	
	if position != Vector3.INF:
		game.world.add_child(item)
		game.world.entities.append(item)
		
		item.set_real_position(position)
	
	return item

func is_tile_empty(tile: Vector3i) -> bool:
	return not has_box(tile) and not has_structure(tile)

func has_box(tile: Vector3i):
	return tile in game.world.box_data

func has_structure(tile: Vector3i):
	return tile in game.world.structure_data

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
