@tool
extends Control

@onready var add_source_node = $VBoxContainer/ToolBar/AddSourceNode

@onready var graph_editor = $VBoxContainer/GraphEditor

@onready var popup_control = $Control
@onready var popup_title   = $Control/popup/Popup/Title/HBoxContainer/Label
@onready var popup_close   = $Control/popup/Popup/Title/HBoxContainer/close
@onready var popup_content = $Control/popup/Popup/Content
@onready var popup_action  = $Control/popup/Popup/Action/Button

@onready var clear_button   = $VBoxContainer/ToolBar/clear
@onready var debug_button   = $VBoxContainer/ToolBar/debug
@onready var save_button    = $VBoxContainer/ToolBar/save
@onready var load_button    = $VBoxContainer/ToolBar/load

const source_node_scene   = preload("res://addons/object_flow_editor/source_node.tscn")
const resource_node_scene = preload("res://addons/object_flow_editor/resource_node.tscn")
const tool_node_scene     = preload("res://addons/object_flow_editor/tool_node.tscn")
const drops_node_scene    = preload("res://addons/object_flow_editor/drops.tscn")
const sequence_node_scene = preload("res://addons/object_flow_editor/hit_sequence_node.tscn")
const recipe_node_scene   = preload("res://addons/object_flow_editor/recipe_node.tscn")

const panel_base   = preload("res://addons/object_flow_editor/styles/panel_base.tres")
const title_source = preload("res://addons/object_flow_editor/styles/title_source.tres")

var selected_nodes = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	popup_control.visible = false
	
	popup_close.icon  = get_theme_icon("Close", "EditorIcons")
	clear_button.icon = get_theme_icon("Clear", "EditorIcons")
	debug_button.icon = get_theme_icon("Debug", "EditorIcons")
	save_button.icon  = get_theme_icon("Save", "EditorIcons")
	load_button.icon  = get_theme_icon("Load", "EditorIcons")
	
	#load_sources()

func create_popup_input(title:String, label_name:String, placeholder:String = "") -> Node:
	var new_container = HBoxContainer.new()
	new_container.name = title
	
	var new_label = Label.new()
	new_label.text = label_name
	new_container.add_child(new_label)
	
	var new_input = LineEdit.new()
	new_input.placeholder_text = placeholder
	new_input.name = "input"
	new_input.size_flags_horizontal += Control.SIZE_EXPAND
	new_container.add_child(new_input)
	
	return new_container

func _on_add_item_pressed() -> void:
	popup_control.visible = true
	popup_title.text = "Add new item node"
	
	for i in popup_content.get_children():
		popup_content.remove_child(i)
	
	popup_content.add_child(create_popup_input("item_name", "Name", "new_item"))
	
	for i in popup_action.pressed.get_connections():
		popup_action.pressed.disconnect(i.callable)
	popup_action.pressed.connect(self.new_item_node)

func new_item_node():
	var value = popup_content.get_node("item_name/input").text
	if value != "" && !graph_editor.has_node("item$" + value):
		popup_control.visible = false

		var new_node := source_node_scene.instantiate()
		new_node.add_to_group("Source")
		new_node.title = value
		new_node.name  = "item$" + value
		
		graph_editor.add_child(new_node)
		return new_node
	return null

# Source Node
# -----------------------------------------------------------------------------------------------------------
func _on_add_source_node_pressed():
	popup_control.visible = true
	popup_title.text = "Add new source node"
	
	for i in popup_content.get_children():
		popup_content.remove_child(i)
	
	popup_content.add_child(create_popup_input("source_name", "Name", "new_source"))
	
	for i in popup_action.pressed.get_connections():
		popup_action.pressed.disconnect(i.callable)
	popup_action.pressed.connect(self.new_source_node)

func new_source_node():
	var value = popup_content.get_node("source_name/input").text
	if value != "" && !graph_editor.has_node("source$" + value):
		popup_control.visible = false

		var new_node := source_node_scene.instantiate()
		new_node.add_to_group("Source")
		new_node.title = value
		new_node.name  = "source$" + value
		
		graph_editor.add_child(new_node)
		return new_node
	return null

func _on_close_pressed():
	popup_control.visible = false

# Resource Node
# -----------------------------------------------------------------------------------------------------------
func _on_add_resource_node_pressed():
	popup_control.visible = true
	popup_title.text = "Add new resource node"
	
	for i in popup_content.get_children():
		popup_content.remove_child(i)
	
	popup_content.add_child(create_popup_input("resource_name", "Name", "new_resource"))
	
	for i in popup_action.pressed.get_connections():
		popup_action.pressed.disconnect(i.callable)
	popup_action.pressed.connect(self.new_resource_node)

func new_resource_node():
	var value = popup_content.get_node("resource_name/input").text
	if value != "" && !graph_editor.has_node("resource$" + value):
		popup_control.visible = false
		
		var new_node = resource_node_scene.instantiate()
		new_node.add_to_group("Resource")
		new_node.title = value
		new_node.name  = "resource$" + value
		
		graph_editor.add_child(new_node)
		return new_node
	return null

# Tool Node
# -----------------------------------------------------------------------------------------------------------
func _on_add_tool_pressed():
	popup_control.visible = true
	popup_title.text = "Add new tool node"
	
	for i in popup_content.get_children():
		popup_content.remove_child(i)
	
	popup_content.add_child(create_popup_input("tool_name", "Name", "new_tool"))
	
	for i in popup_action.pressed.get_connections():
		popup_action.pressed.disconnect(i.callable)
	popup_action.pressed.connect(self.new_tool_node)

func new_tool_node():
	var value = popup_content.get_node("tool_name/input").text
	if value != "" && !graph_editor.has_node("tool$" + value):
		popup_control.visible = false
		
		var new_node = tool_node_scene.instantiate()
		new_node.add_to_group("Tool")
		new_node.title = value
		new_node.name  = "tool$" + value
		
		graph_editor.add_child(new_node)
		return new_node
	return null

# Drops Node
# -----------------------------------------------------------------------------------------------------------
func add_drops_node(from_node, from_port, release_position):
	var new_node := drops_node_scene.instantiate()
	new_node.add_to_group("Drops")
	new_node.position = release_position
	new_node.title    = "Drops"
	new_node.name     = "drops$" + graph_editor.get_node(NodePath(from_node)).title + "-" + str(from_port)
	
	graph_editor.add_child(new_node)
	graph_editor.connect_node(from_node, from_port, new_node.name, 0)
	return new_node

# GraphEdit Signals
# -----------------------------------------------------------------------------------------------------------
func _on_graph_editor_connection_request(from_node, from_port, to_node, to_port):
	var from_n = graph_editor.get_node(NodePath(from_node))
	var to_n   = graph_editor.get_node(NodePath(to_node))
	
	graph_editor.connect_node(from_node, from_port, to_node, to_port)

	if from_n.is_in_group("Tool") && to_n.is_in_group("Resource"):
		pass

func _on_graph_editor_disconnection_request(from_node, from_port, to_node, to_port):
	print("disconect request")

func _on_graph_editor_connection_to_empty(from_node, from_port, release_position):
	var from_n = graph_editor.get_node(NodePath(from_node))
	if from_n.is_in_group("Source") and from_port == 1:
		var new_node := sequence_node_scene.instantiate()
		new_node.add_to_group("HitSequence")
		new_node.name     = "hit_sequence$" + graph_editor.get_node(NodePath(from_node)).title + "-" + str(from_port)
		
		graph_editor.add_child(new_node)
		new_node.position = release_position
		graph_editor.connect_node(from_node, from_port, new_node.name, 0)
	elif from_n.is_in_group("Resource") and from_port == 0:
		var new_node := recipe_node_scene.instantiate()
		new_node.add_to_group("Recipe")
		new_node.name     = "recipe$" + graph_editor.get_node(NodePath(from_node)).title + "-" + str(from_port)
		
		graph_editor.add_child(new_node)
		new_node.position = release_position
		new_node.create_ingredient()
		graph_editor.connect_node(from_node, from_port, new_node.name, 0)
	elif from_n.is_in_group("HitSequence") || from_n.is_in_group("Resource") and from_port > 1:
		var new_node := drops_node_scene.instantiate()
		new_node.add_to_group("Drops")
		new_node.position = release_position
		new_node.title    = "Drops"
		new_node.name     = "drops$" + graph_editor.get_node(NodePath(from_node)).title + "-" + str(from_port)
		
		graph_editor.add_child(new_node)
		graph_editor.connect_node(from_node, from_port, new_node.name, 0)

func _on_graph_editor_delete_nodes_request(nodes):
	for i in graph_editor.get_connection_list():
		if i.get("from_node") in nodes || i.get("to_node") in nodes: 
			graph_editor.disconnect_node(i.get("from_node"), i.get("from_port"), i.get("to_node"), i.get("to_port"))
	
	for i in nodes: 
		var node = graph_editor.get_node(NodePath(i))
		graph_editor.remove_child(node)
		node.queue_free()

# Options Signals
# -----------------------------------------------------------------------------------------------------------
func _on_debug_pressed():
	print(graph_editor.get_connection_list())

func _on_clear_pressed():
	graph_editor.clear_connections()
	for i in graph_editor.get_children():
		graph_editor.remove_child(i)
		i.queue_free()

func _on_save_pressed():
	#save_sources(get_sources_dict(graph_editor.get_connection_list()))
	#save_resources(get_resources_dict(graph_editor.get_connection_list()))
	pass

func _on_rearrange_pressed():
	graph_editor.arrange_nodes()

func _on_load_pressed():
	#load_sources()
	#load_resources()
	pass

# Store data
# -----------------------------------------------------------------------------------------------------------
@onready var source_data_file = "res://metadata/source.txt"
@onready var resource_data_file = "res://metadata/resource.txt"

func get_sources_dict(dict):
	var sources = {}
		
	for i in graph_editor.get_children():
		var node = i.name.split("$")
		if node[0] == "source" && node[1] not in sources:
			sources[node[1]] = i.get_data()
	
	return sources

func get_resources_dict(dict):
	var resources = {}
	
	for i in graph_editor.get_children():
		var node = i.name.split("$")
		if node[0] == "resource" && node[1] not in resources:
			resources[node[1]] = i.get_data()
	
	return resources

func save_sources(dict):
	var file = FileAccess.open(source_data_file, FileAccess.WRITE)
	file.store_string(JSON.stringify(dict))
	file.close()

func save_resources(dict):
	var file = FileAccess.open(resource_data_file, FileAccess.WRITE)
	file.store_string(JSON.stringify(dict))
	file.close()

func load_sources():
	var json = JSON.new()
	var file = FileAccess.open(source_data_file, FileAccess.READ)
	
	var error = json.parse(file.get_as_text())
	for i in json.data.keys():
		popup_content.add_child(create_popup_input("source_name", "Name", "new_source"))
		popup_control.visible = false
		popup_content.get_node("source_name/input").text = i
		
		var s_node = new_source_node()
		
		for j in json.data[i]["efficiency"]:
			var control = s_node.create_tool_efficiency()
			control.get_node("name").text   = j["tool"]
			control.get_node("value").value = j["multiplier"]
		
		var slot = 0
		
		for j in json.data[i]["hit_sequence"]:
			var control = s_node.create_hit_points()
			control.get_node("value").value = j["hits"]
			
			var drop_slot = 0
			
			for k in j["drops"]:
				popup_content.add_child(create_popup_input("resource_name", "Name", "new_source"))
				popup_control.visible = false
				popup_content.get_node("resource_name/input").text = k["resource"]
				
				var res_node = new_resource_node()
				if !graph_editor.has_node("drops$" + i + "-"+ str(slot)):
					var drops = add_drops_node("source$" + i, slot, Vector2.ZERO)
					var drop = drops.create_drop()
					
					drop.get_node("count").value  = k["ammount"]
					drop.get_node("chance").value = k["chance"]
					
					graph_editor.connect_node(drops.name, drop_slot, "resource$" + k["resource"], 0)
				else:
					var drops = graph_editor.get_node("drops$" + i + "-"+ str(slot))
					var drop = drops.create_drop()
					
					drop.get_node("count").value  = k["ammount"]
					drop.get_node("chance").value = k["chance"]
					
					graph_editor.connect_node(drops.name, drop_slot, "resource$" + k["resource"], 0)
				drop_slot += 1
			slot += 1

func load_resources():
	var json = JSON.new()
	var file = FileAccess.open(resource_data_file, FileAccess.READ)
	var error = json.parse(file.get_as_text())
	
	for i in json.data.keys():
		if !graph_editor.has_node("resource$" + i):
			popup_content.add_child(create_popup_input("resource_name", "Name", "new_source"))
			popup_control.visible = false
			popup_content.get_node("resource_name/input").text = i
			
			new_resource_node()
	
	for i in json.data.keys():
		var resource = graph_editor.get_node("resource$" + i)
		
		resource.set_collectable(json.data[i].collectable == "yes")
		if json.data[i].collectable == "no":
			var slot = 0
		
			for j in json.data[i]["breakable"]:
				var control = resource.create_tool()
				control.get_node("name").text = j["tool"]
				
				var drop_slot = 0
				
				for k in j["drops"]:
					var drops
					
					if !graph_editor.has_node("drops$" + i + "-"+ str(slot)): drops = add_drops_node("resource$" + i, slot, Vector2.ZERO)
					else: drops = graph_editor.get_node("drops$" + i + "-"+ str(slot))
					
					var drop = drops.create_drop()
					
					drop.get_node("count").value  = k["ammount"]
					drop.get_node("chance").value = 1
					
					graph_editor.connect_node(drops.name, drop_slot, "resource$" + k["resource"], 0)
					drop_slot += 1
				slot += 1
			
			for j in json.data[i]["ingredients"]:
				var control = resource.create_ingredient()
				control.get_node("name").text = j["resource"]
				control.get_node("value").value = j["ammount"]
				
				graph_editor.connect_node(resource.name, slot, "resource$" + j["result"], 0)
				slot += 1
