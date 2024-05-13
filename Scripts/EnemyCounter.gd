extends Control


func _process(delta):
	var enemies = get_tree().get_nodes_in_group("Game")[0].enemies_remain
	$Enemies.text = "ENEMIES " + str(enemies)
	$Added.modulate.a = $TimeAdd.get_time_left()

func _kill_enemy():
	$Added.text = "-1"
	$TimeAdd.start()
