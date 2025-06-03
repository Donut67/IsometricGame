extends Control

func _input(event):
	if event.is_action_pressed("ui_cancel"): _toggle_pause()

func _toggle_pause():
	print("toggle")
	visible = not visible
	Engine.time_scale = 0 if visible else 1

func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	Global._goto_scene("game")

func _on_menu_pressed() -> void:
	get_tree().paused = false
	Global._goto_scene("title")
