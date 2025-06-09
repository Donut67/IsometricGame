extends Node

var max_round = 0
var current_scene = null

const TILE_SIZE := preload("res://TileSets/box_tileset.tres").tile_size  # Width x Height of one tile
const LAYER_HEIGHT := 9  # Vertical pixels per Z-layer (stack height)

const TITLE = preload("res://Scenes/Game/TitleScreen.tscn")
const GAME = preload("res://Scenes/Game/InGame.tscn")
const END = preload("res://Scenes/Game/EndScreen.tscn")

const BASE_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Base_Character.png")
const BOY_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Boy_Character.png")
const GIRL_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Girl_Character.png")

var current_character = BASE_CHARACTER_TEXTURE

#func _ready():
	#var root = get_tree().get_root()
	#current_scene = root.get_child(root.get_child_count() - 1)

func _goto_scene(val):
	call_deferred("_deferrend_goto_scene", val)

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
