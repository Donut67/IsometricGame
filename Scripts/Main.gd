extends Node2D

var INITIAL = preload("res://Scenes/Game/TitleScreen.tscn")
var INGAME = preload("res://Scenes/Game/InGame.tscn")
var END = preload("res://Scenes/Game/EndScreen.tscn")

func _ready():
	var scene = INITIAL.instance()
	call_deferred("add_child", scene)

func load_game():
	get_child(0).queue_free()
	var scene = INGAME.instance()
	call_deferred("add_child", scene)

func load_menu():
	get_child(0).queue_free()
	var scene = INITIAL.instance()
	call_deferred("add_child", scene)

func load_end():
	var last_round = get_child(0)._round
	get_child(0).queue_free()
	var scene = END.instance()
	scene.get_child(0).text = "FINAL WROUND - " + String(last_round)
	call_deferred("add_child", scene)
	
