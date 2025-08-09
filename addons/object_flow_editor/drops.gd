@tool
extends GraphNode

var hits_sequence = []

# Creation Functions
# -----------------------------------------------------------------------------------------------------------
func create_drop():
	var control = HBoxContainer.new()

	var delete = Button.new()
	delete.icon = get_theme_icon("Close", "EditorIcons")
	control.add_child(delete)
	
	var ammount = SpinBox.new()
	ammount.name = "count"
	ammount.tooltip_text = "count"
	ammount.min_value = 1
	ammount.value = 1
	control.add_child(ammount)
	
	var chance = SpinBox.new()
	chance.name = "chance"
	chance.tooltip_text = "chance"
	chance.min_value = 0
	chance.max_value = 1
	chance.step      = 0.1
	chance.value     = 1
	control.add_child(chance)
	
	add_child(control)
	move_child(control, get_child_count() - 2)
	set_slot_enabled_right(get_child_count() - 2, true)
	set_slot_color_right(get_child_count() - 2, Color.hex(0xc42d44ff))
	
	delete.pressed.connect(delete_hit_points_label.bind(control))
	
	return control

# Removal Functions
# -----------------------------------------------------------------------------------------------------------
func delete_hit_points_label(child):
	var pos = 0
	for i in get_children():
		if i == child: break
		pos =+ 1
	
	for i in get_parent().get_connection_list():
		if i.get("from_node") == name: 
			if i.get("from_port") == pos: get_parent().disconnect_node(i.get("from_node"), i.get("from_port"), i.get("to_node"), i.get("to_port"))
			elif i.get("from_port") > pos: 
				get_parent().disconnect_node(i.get("from_node"), i.get("from_port"), i.get("to_node"), i.get("to_port"))
				get_parent().connect_node(i.get("from_node"), i.get("from_port") - 1, i.get("to_node"), i.get("to_port"))
	
	remove_child(child)
	reset_size()
	set_slot_enabled_right(get_child_count() - 1, false)

# Button Signals
# -----------------------------------------------------------------------------------------------------------
func _on_button_pressed():
	create_drop()
