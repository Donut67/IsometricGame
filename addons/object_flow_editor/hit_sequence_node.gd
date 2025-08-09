@tool
extends GraphNode

# Creation Functions
# -----------------------------------------------------------------------------------------------------------
func create_hit_points():
	var control = HBoxContainer.new()
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.add_child(spacer)

	var delete = Button.new()
	delete.icon = get_theme_icon("Close", "EditorIcons")
	control.add_child(delete)
	
	var spin_box   = SpinBox.new()
	spin_box.name  = "value"
	spin_box.value = 1
	spin_box.tooltip_text = "Number of hits"
	control.add_child(spin_box)
	
	add_child(control)
	move_child(control, get_child_count() - 2)
	set_slot_enabled_right(get_child_count() - 2, true)
	set_slot_color_right(get_child_count() - 2, Color.hex(0x2b8c7fff))

	delete.pressed.connect(delete_hit_points.bind(control))
	
	return control

# Removal Functions
# -----------------------------------------------------------------------------------------------------------
func delete_hit_points(child):
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
func _on_add_tool_pressed():
	create_hit_points()
