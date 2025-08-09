@tool
extends GraphNode

@onready var add_tool = $add_tool

var slot = 0

func _ready():
	create_tool_efficiency()

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
	
	var spin_box = SpinBox.new()
	spin_box.name = "value"
	spin_box.value = 1
	control.add_child(spin_box)
	
	$ToolEfficiencies.add_child(control)
	$ToolEfficiencies.move_child(control, $ToolEfficiencies.get_child_count() - 2)
	
	delete.pressed.connect(delete_tool_efficiency.bind(control))
	
	return control

# Removal Functions
# -----------------------------------------------------------------------------------------------------------
func delete_tool_efficiency(child):
	$ToolEfficiencies.remove_child(child)

# Button Signals
# -----------------------------------------------------------------------------------------------------------
func _on_add_tool_pressed():
	create_tool_efficiency()
