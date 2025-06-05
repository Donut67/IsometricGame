extends Node

var max_round = 0
var current_scene = null

const TITLE = preload("res://Scenes/Game/TitleScreen.tscn")
const GAME = preload("res://Scenes/Game/InGame.tscn")
const END = preload("res://Scenes/Game/EndScreen.tscn")

const BASE_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Base_Character.png")
const BOY_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Boy_Character.png")
const GIRL_CHARACTER_TEXTURE = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/Girl_Character.png")

var current_character = BASE_CHARACTER_TEXTURE

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

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
