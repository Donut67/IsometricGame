extends Control


func _on_Start_Game_pressed():
	Global._goto_scene("game")

func _on_Exit_pressed():
	get_tree().quit()

func _on_tab_bar_tab_clicked(tab: int) -> void:
	Global._change_character(tab)
