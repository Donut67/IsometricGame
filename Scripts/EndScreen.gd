extends Control

func _ready():
	var text = "Cleared " + str(Global.max_round)
	$CenterContainer/Round.text = text + " Rounds" if Global.max_round != 1 else text + " Round" 

func _on_Restart_pressed():
	Global._goto_scene("game")

func _on_InitialPage_pressed():
	Global._goto_scene("title")


func _on_Exit_pressed():
	get_tree().quit()
