tool
extends Control

const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
onready var GraphNodeTemplate = $GraphNodeTemplate

var path
var refreshed = false
var selected_node

onready var original_delete_node_dialog = $DeleteNodeDialog.dialog_text

func _ready():
	for menu_button in [$Menu/File]:
		menu_button.get_popup().connect('index_pressed', self, '_on_menu_pressed', [menu_button.get_popup()])

	$GraphEdit.connect('gui_input', self, '_on_graph_edit_input')
	$GraphEdit.connect('node_selected', self, '_on_node_selected', [true])
	$GraphEdit.connect('node_unselected', self, '_on_node_selected', [false])

	$DeleteNodeDialog.connect('confirmed', self, 'delete_node')

	# TODO: Conditionally load in theme based on Editor or standalone

	path = 'res://dialogue.wol'
	build_nodes()

func create_node(position = Vector2.ZERO):
	print('creating node!')
	var graph_node = GraphNodeTemplate.duplicate()
	$GraphEdit.add_child(graph_node)

	var node = {
		'title': 'NewNode',
		'body': 'Wol: Hello world',
		'position': position
	}

	graph_node.connect('recompiled', self, '_on_graph_node_recompiled', [graph_node])
	graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node, node])

	graph_node.node = node
	graph_node.show()

func delete_node(node = selected_node):
	$GraphEdit.remove_child(node)
	node.queue_free()

func build_nodes():
	for node in Compiler.new(path).get_nodes():
		var graph_node = GraphNodeTemplate.duplicate()
		$GraphEdit.add_child(graph_node)

		graph_node.connect('recompiled', self, '_on_graph_node_recompiled', [graph_node])
		graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node, node])

		graph_node.node = node
		graph_node.show()

func serialize_to_file():
	var buffer = []
	for graph_node in $GraphEdit.get_children():
		if not graph_node is GraphNode:
			continue

		var node = graph_node.node
		buffer.append('title: %s' % node.title)
		buffer.append('tags: ')
		buffer.append('colorID: ')
		buffer.append('position: %d, %d' % [node.position.x, node.position.y])
		buffer.append('---')
		buffer.append(node.body)
		buffer.append('===')

	return PoolStringArray(buffer).join('\n')

func save_as(file_path = null):
	if not file_path:
		$FileDialog.mode = $FileDialog.MODE_SAVE_FILE
		# TODO: Set up path based on context (Godot editor, standalone or web)
		$FileDialog.popup_centered()
		file_path = yield($FileDialog, 'file_selected')

		if not file_path:
			return
	
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(serialize_to_file())
	file.close()
	print('saved file!')

func open():
	$FileDialog.mode = $FileDialog.MODE_OPEN_FILE
	# TODO: Set up path based on context (Godot editor, standalone or web)
	$FileDialog.popup_centered()
	path = yield($FileDialog, 'file_selected')
	if not path:
		return

	for node in $GraphEdit.get_children():
		if node is GraphNode:
			$GraphEdit.remove_child(node)
			node.queue_free()

	yield(get_tree(), 'idle_frame')
	build_nodes()

func new():
	# TODO: add dialog for maybe saving existing file
	
	for node in $GraphEdit.get_children():
		if node is GraphNode:
			$GraphEdit.remove_child(node)
			node.queue_free()

	path = null

func _on_menu_pressed(index, node):
	match(node.get_item_text(index)):
		'New':
			new()
		'Save':
			save_as(path)
		'Save as...':
			save_as()
		'Open':
			open()

# FIXME: Come up with better way of showing connections between nodes
func _on_graph_node_recompiled(_graph_node):
	if refreshed: return
	$GraphEdit.clear_connections()
	for graph_node in $GraphEdit.get_children():
		if not graph_node is GraphNode:
			continue

		var connections = graph_node.get_connections()
		graph_node.set_slot_enabled_right(0, connections.size() != 0)
		graph_node.set_slot_type_right(0, 1)

		for connection in connections:
			if not $GraphEdit.has_node(connection):
				continue

			var other_graph_node = $GraphEdit.get_node(connection)
			other_graph_node.set_slot_enabled_left(0, true)
			other_graph_node.set_slot_type_left(0, 1)

			$GraphEdit.connect_node(graph_node.name, 0, connection, 0)

	refreshed = true
	yield(get_tree().create_timer(.3), 'timeout')
	refreshed = false

func _on_graph_node_input(event, graph_node, node):
	if event is InputEventMouseButton \
			and event.doubleclick and event.button_index == BUTTON_LEFT:
		$HBoxContainer/Editor.open_node(graph_node, node)
		accept_event()

func _on_node_selected(node, selected):
	if not selected:
		selected_node = null
	else:
		selected_node = node

func _on_graph_edit_input(event):
	if event is InputEventMouseButton \
			and event.doubleclick and event.button_index == BUTTON_LEFT:
		create_node(event.global_position + $GraphEdit.scroll_offset)

func _input(event):
	if event is InputEventKey \
			and not event.pressed and event.scancode == KEY_DELETE \
			and selected_node:
		$DeleteNodeDialog.dialog_text = original_delete_node_dialog % selected_node.name
		$DeleteNodeDialog.popup()
		
