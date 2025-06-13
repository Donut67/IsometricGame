extends Node

const TILE_SIZE := preload("res://TileSets/box_tileset.tres").tile_size  # Width x Height of one tile
const LAYER_HEIGHT := 9  # Vertical pixels per Z-layer (stack height)

const TITLE = preload("res://Scenes/Game/TitleScreen.tscn")
const GAME = preload("res://Scenes/Game/InGame.tscn")
const END = preload("res://Scenes/Game/EndScreen.tscn")

const BASE_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Base_Character.png")
const BOY_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Boy_Character.png")
const GIRL_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Girl_Character.png")

var current_character = BASE_CHARACTER_TEXTURE
var max_round = 0
var current_scene = null
var recipe_list: Array = []

const items_atlas_coords: Dictionary = {
	"metal_scrap": Vector2i(0, 0),
	"plastic_chunk": Vector2i(1, 0),
	"carbon_dust": Vector2i(2, 0),
	"metal_panel": Vector2i(0, 1),
	"reinforced_scrap": Vector2i(1, 1),
	"raw_frame_part": Vector2i(2, 1),
	"insulation_patch": Vector2i(3, 1),
	"insulated_joint": Vector2i(4, 1),
	"plastic_shell": Vector2i(5, 1),
	"coated_wiring": Vector2i(6, 1),
	"basic_connector": Vector2i(7, 1),
	"crude_circuit": Vector2i(8, 1),
	"machine_frame_base": Vector2i(9, 1),
	"machine_frame_part": Vector2i(10, 1),
	"smelter": Vector2i(11, 1)
}

func _ready():
	var json: = FileAccess.open("res://Assets/recipes.tres", FileAccess.READ)
	var txt: String = json.get_as_text()
	var cropped = txt.right(-(txt.find("data = ") + 7))
	recipe_list = JSON.parse_string(cropped)
	
	#for recipe in recipe_list:
		#var key = get_recipe_key(recipe["input"])
		#recipe_map[key] = recipe
		
func get_recipe_key(items: Array) -> String:
	items.sort()
	return ",".join(items)

func find_recipe(items: Array[String]) -> Dictionary:
	for recipe in recipe_list:
		var this = get_recipe_key(recipe["input"])
		var that = get_recipe_key(items)
		
		if this == that: return recipe
	
	return {}

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
	var x = ((screen_pos.x / (TILE_SIZE.x / 2)) + (adj_y / (TILE_SIZE.y / 2))) / 2
	var y = ((adj_y / (TILE_SIZE.y / 2)) - (screen_pos.x / (TILE_SIZE.x / 2))) / 2

	return Vector3i(round(x), round(y), z)

# Convert screen position (Vector2) + z → grid position (Vector3i)
func screen_to_grid_f(screen_pos: Vector2, z: float) -> Vector3:
	# Remove vertical layer offset
	var adj_y = screen_pos.y + z * LAYER_HEIGHT

	# Invert isometric projection
	var x = ((screen_pos.x / (TILE_SIZE.x / 2)) + (adj_y / (TILE_SIZE.y / 2))) / 2
	var y = ((adj_y / (TILE_SIZE.y / 2)) - (screen_pos.x / (TILE_SIZE.x / 2))) / 2

	return Vector3(x, y, z)

func intersect(array1, array2):
	var intersection = []
	
	for item in array1:
		if array2.has(item):
			intersection.append(item)
	
	return intersection
