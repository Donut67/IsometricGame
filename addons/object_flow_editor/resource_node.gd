@tool
extends GraphNode

@onready var h_separator_2  = $HSeparator2
@onready var check_box      = $is_collectable/CheckBox

var slot = 0

# Creation Functions
# -----------------------------------------------------------------------------------------------------------
func create_tool():
	var control = HBoxContainer.new()
	control.name = "tool_name"

	var delete = Button.new()
	delete.icon = get_theme_icon("Close", "EditorIcons")
	control.add_child(delete)
	
	var resource = LineEdit.new()
	resource.placeholder_text = "Tool Name"
	resource.name = "name"
	resource.custom_minimum_size = Vector2(125, 0)
	control.add_child(resource)
	
	var pos = 0
	for i in get_children():
		if i.name == "add_tool": break
		pos += 1
	
	add_child(control)
	move_child(control, pos)
	set_slot_enabled_right(pos, true)
	set_slot_color_right(pos, Color.hex(0x2b8c7fff))

	delete.pressed.connect(delete_tool.bind(control))
	
	return control

# Removal Functions
# -----------------------------------------------------------------------------------------------------------
func delete_tool(child):
	var pos = 0
	for i in get_children():
		if i == child: break
		pos += 1
		
	var last = 0
	for i in get_children():
		if i.name == "add_tool": break
		last += 1
		
	for i in get_parent().get_connection_list():
		if i.get("from_node") == name: 
			if i.get("from_port") == pos: get_parent().disconnect_node(i.get("from_node"), i.get("from_port"), i.get("to_node"), i.get("to_port"))
			elif i.get("from_port") > pos: 
				get_parent().disconnect_node(i.get("from_node"), i.get("from_port"), i.get("to_node"), i.get("to_port"))
				get_parent().connect_node(i.get("from_node"), i.get("from_port") - 1, i.get("to_node"), i.get("to_port"))
	
	remove_child(child)
	reset_size()
	set_slot_enabled_right(last - 1, false)

# Data Functions
# -----------------------------------------------------------------------------------------------------------
func reduce_breakable(acc, curr): 
	if "tool_name" in curr.name:
		var dict = get_parent().get_connection_list()
		var drops  = []
		
		for i in dict.filter(func(elem): return elem.get("from_node") == name && elem.get("from_port") == slot):
			for j in dict.filter(func(elem): return elem.get("from_node") == i.get("to_node")):
				var from_n = get_parent().get_node(NodePath(j.get("from_node")))
				var drop_n = from_n.get_child(j.get("from_port"))
				
				drops.push_back({
					"resource": j.get("to_node").split("$")[1], 
					"ammount": drop_n.get_node("count").value
				})
		
		var value = [{
			"tool": curr.get_node("name").text,
			"drops": drops
		}]
		slot += 1
		return acc + value
	return acc

func reduce_ingredients(acc, curr): 
	if "ingredient_name" in curr.name:
		var dict = get_parent().get_connection_list()
		var result
		
		for i in dict.filter(func(elem): return elem.get("from_node") == name && elem.get("from_port") == slot):
			result = i.get("to_node")
				
		var value = [{
			"resource": curr.get_node("name").text,
			"ammount": curr.get_node("value").value,
			"result": result.split("$")[1]
		}]
		slot += 1
		return acc + value
	return acc

func get_data():
	slot = 0
	var data = {}
	data["name"] = title
	data["collectable"] = "yes" if $HBoxContainer/CheckBox.button_pressed else "no"
	
	if not $HBoxContainer/CheckBox.button_pressed:
		data["breakable"] = get_children().reduce(reduce_breakable, [])
		data["ingredients"] = get_children().reduce(reduce_ingredients, [])

	return data

func set_collectable(toggle):
	check_box.button_pressed = toggle

# Button Signals
# -----------------------------------------------------------------------------------------------------------
func _on_check_box_toggled(toggled_on):
	set_collectable(toggled_on)
		
func _on_add_tool_pressed():
	create_tool()
