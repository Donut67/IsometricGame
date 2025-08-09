@tool
extends GraphNode

@onready var add_tool = $ToolEfficiencies/add_tool

var slot = 0

# Creation Functions
# -----------------------------------------------------------------------------------------------------------
func create_tool_efficiency():
	var control = HBoxContainer.new()
	
	var delete = Button.new()
	delete.icon = get_theme_icon("Close", "EditorIcons")
	control.add_child(delete)
	
	var tool = LineEdit.new()
	tool.placeholder_text = "Tool Name"
	tool.name = "name"
	tool.custom_minimum_size = Vector2(125, 0)
	control.add_child(tool)
	
	var spin_box   = SpinBox.new()
	spin_box.name  = "value"
	spin_box.value = 1
	spin_box.tooltip_text = "Efficiency"
	control.add_child(spin_box)
	
	$ToolEfficiencies.add_child(control)
	$ToolEfficiencies.move_child(control, $ToolEfficiencies.get_child_count() - 2)
	
	delete.pressed.connect(delete_tool_efficiency.bind(control))
	
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

func delete_tool_efficiency(child):
	$ToolEfficiencies.remove_child(child)
	reset_size()

# Data Functions
# -----------------------------------------------------------------------------------------------------------
func reduce_efficiencies(acc, curr): 
	if "HBoxContainer" in curr.name:
		var value = [{
			"tool": curr.get_node("name").text, 
			"multiplier": curr.get_node("value").value
		}]
		return acc + value
	return acc

func reduce_hit_sequence(acc, curr): 
	if "HBoxContainer" in curr.name:
		var dict = get_parent().get_connection_list()
		var drops  = []
		
		for i in dict.filter(func(elem): return elem.get("from_node") == name && elem.get("from_port") == slot):
			for j in dict.filter(func(elem): return elem.get("from_node") == i.get("to_node")):
				var from_n = get_parent().get_node(NodePath(j.get("from_node")))
				var drop_n = from_n.get_child(j.get("from_port"))
				
				drops.push_back({
					"resource": j.get("to_node").split("$")[1], 
					"ammount": drop_n.get_node("count").value,
					"chance": drop_n.get_node("chance").value
				})
		
		var value = [{
			"hits": curr.get_node("value").value,
			"drops": drops
		}]
		slot += 1
		return acc + value
	return acc

func get_data():
	slot = 0
	var data = {
		"name": title,
		"efficiency": $ToolEfficiencies.get_children().reduce(reduce_efficiencies, []),
		"hit_sequence": get_children().reduce(reduce_hit_sequence, [])
	}

	return data

# Button Signals
# -----------------------------------------------------------------------------------------------------------
func _on_add_tool_pressed():
	create_tool_efficiency()
