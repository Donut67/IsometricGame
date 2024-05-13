extends Node2D

@onready var _round = 1
var initial_enemies = 3
var enemies_remain = 0
var rng = RandomNumberGenerator.new()
const SLIME = preload("res://Scenes/Objects/Slime.tscn")

func _ready():
	_spawn_enemies()

func _process(delta):
	update_radar()
	enemies_remain = $YSort/Entities.get_child_count() - 1
	if enemies_remain == 0: _end_round()
	if get_tree().get_nodes_in_group("player")[0].lives == 0: Global._goto_scene("end")
	$HUD/HBoxContainer/Round.text = "ROUND " + str(_round)


func update_radar():
	var list = []
	$HUD/Radar.reset_radar()
	for i in range(enemies_remain):
		if get_tree().get_nodes_in_group("Entities")[0].get_child(i + 1):
			var enemy_pos = get_tree().get_nodes_in_group("Entities")[0].get_child(i + 1).get_global_position()
			var player_pos = get_tree().get_nodes_in_group("Entities")[0].get_child(0).get_global_position()
			var angle = atan2(enemy_pos.y - player_pos.y, enemy_pos.x - player_pos.x) * 180 / PI
			$HUD/Radar.choose_dir(angle)


func _spawn_enemies():
	var _spawnpoints = get_tree().get_nodes_in_group("SpawnPoints")[0]
	var n = _spawnpoints.get_child_count()
	for i in range(initial_enemies + int(_round / 3) if initial_enemies + int(_round / 3) < 15 else 15):
		rng.randomize()
		var s = rng.randi_range(0, n-1)
		var scene = SLIME.instantiate()
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 175
		scene.set_position(_spawnpoints.get_child(s).get_position() + offset)
		get_tree().get_nodes_in_group("Entities")[0].call_deferred("add_child", scene)
	


func _end_round():
	Global.max_round = _round
	_round += 1
	_spawn_enemies()
	get_tree().get_nodes_in_group("Timer")[0]._set_time(90)

