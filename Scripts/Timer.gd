extends Control

func _process(delta):
	var mins = int($Timer.get_time_left() / 60)
	var secs = int($Timer.get_time_left() - mins * 60)
	mins = str(mins) if mins > 9 else "0" + str(mins)
	secs = str(secs) if secs > 9 else "0" + str(secs)
	var time = mins + ":" + secs
	$Time.text = "TIME LEFT  " + time
	$Added.modulate.a = $TimeAdd.get_time_left()


func _set_time(amount):
	$Added.text = "+" + str(amount - int($Timer.get_time_left()))
	$Timer.start(amount)
	$TimeAdd.start()


func _add_time(amount):
	$Added.text = "+" + str(amount)
	$Timer.start($Timer.get_time_left() + amount)
	$TimeAdd.start()


func _on_Timer_timeout():
	get_tree().get_nodes_in_group("Game")[0]._end_round()
