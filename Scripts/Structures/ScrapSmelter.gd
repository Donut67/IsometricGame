class_name ScrapSmelter
extends Structure

func _ready() -> void:
	super._ready()
	structure_type = "scrap_smelter"

func _process(delta: float) -> void:
	super._process(delta)
	
	$Panel.visible = "time" in current_recipe
	
	if $Panel.visible:
		var stylebox = $Panel.get_theme_stylebox("panel").duplicate()
		stylebox.border_width_left = (progress) * 16 / current_recipe.time
		$Panel.add_theme_stylebox_override("panel", stylebox)
