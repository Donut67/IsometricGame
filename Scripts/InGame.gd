extends Node2D

@onready var _round = 1

var initial_enemies = 3
var enemies_remain = 0
var rng = RandomNumberGenerator.new()
var player

@onready var active_indicators = $YSort/Indicators
var current_index = 0

const arrow_texture = preload("res://Assets/Character/Small-8-Direction-Characters_by_AxulArt/8_Direction.png")
const SLIME = preload("res://Scenes/Entities/Slime.tscn")


func _ready():
	player = get_tree().get_nodes_in_group("Entities")[0].get_child(0)
	_spawn_enemies()


func _process(_delta):
	enemies_remain = $YSort/Entities.get_child_count() - 1
	if enemies_remain == 0: _end_round()
	
	update_radar()
	
	if get_tree().get_nodes_in_group("player")[0].lives == 0: Global._goto_scene("end")
	$HUD/HBoxContainer/Round.text = "ROUND " + str(_round)


func update_radar():
	var camera = $YSort/Entities/Player/Camera2D
	var viewport_size = camera.get_viewport_rect().size
	var half_size = viewport_size / camera.zoom * 0.5
	var top_left = camera.get_screen_center_position() - half_size
	var rect = Rect2(top_left + Vector2(8, 8), half_size * 2 - Vector2(16, 16))
	
	reset_radar()
	for i in range(enemies_remain):
		var enemy = get_tree().get_nodes_in_group("Entities")[0].get_child(i + 1)
		var enemy_pos = enemy.get_global_position()
		var player_pos = player.get_global_position()
		
		var intersection = get_contact_point(rect, player_pos, enemy_pos)
		var angle = atan2(enemy_pos.y - player_pos.y, enemy_pos.x - player_pos.x) * 180 / PI
		choose_dir(angle, intersection)
	
	clear_unused()


func reset_radar():
	current_index = 0


func clear_unused():
	for i in range(active_indicators.get_child_count() - current_index):
		active_indicators.get_child(current_index + i).queue_free()


func choose_dir(angle, intersection):
	var indicator
	
	if current_index >= active_indicators.get_child_count():
		indicator = create_indicator()
	else:
		indicator = active_indicators.get_child(current_index)
	
	indicator.global_position = intersection
	angle = fposmod(angle + 90.0, 360.0)  # Shift so 0° = down
	var shifted = fposmod(angle + 22.5, 360.0)  # Shift so 0° maps to sector 0
	var frame = int(floor(shifted / 45.0)) % 8
	
	indicator.frame = frame
	current_index += 1


func create_indicator():
	var new_indicator := Sprite2D.new()
	
	new_indicator.texture = arrow_texture
	new_indicator.hframes = 8
	
	active_indicators.add_child(new_indicator)
	
	return new_indicator


func _spawn_enemies():
	var _spawnpoints = get_tree().get_nodes_in_group("SpawnPoints")[0]
	var n = _spawnpoints.get_child_count()
	for i in range(initial_enemies + int(_round / 3.0) if initial_enemies + int(_round / 3.0) < 15 else 15):
		rng.randomize()
		var s = rng.randi_range(0, n-1)
		var scene = SLIME.instantiate()
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 4
		scene.set_position(_spawnpoints.get_child(s).get_position() + offset)
		get_tree().get_nodes_in_group("Entities")[0].call_deferred("add_child", scene)


func _end_round():
	Global.max_round = _round
	_round += 1
	_spawn_enemies()
	get_tree().get_nodes_in_group("Timer")[0]._set_time(90)

func get_contact_point(rect: Rect2, from: Vector2, to: Vector2) -> Vector2:
	var points = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	]
	
	var edges = [
		[points[0], points[1]], # Top
		[points[1], points[2]], # Right
		[points[2], points[3]], # Bottom
		[points[3], points[0]]  # Left
	]
	
	for edge in edges:
		var intersection = Geometry2D.segment_intersects_segment(from, to, edge[0], edge[1])
		if intersection:
			return intersection  # Point of contact

	return Vector2.INF  # No intersection
