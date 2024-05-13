extends Control

func _input(event):
	if event.is_action_pressed("ui_cancel"): _toggle_pause()


func _toggle_pause():
	get_tree().paused = not get_tree().paused
	visible = not visible


func _on_RESUME_pressed():
	_toggle_pause()


func _on_RESTART_pressed():
	get_tree().paused = false
	Global._goto_scene("game")


func _on_MENU_pressed():
	get_tree().paused = false
	Global._goto_scene("title")
