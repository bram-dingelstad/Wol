tool
extends Control

const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
onready var GraphNodeTemplate = $GraphNodeTemplate

var path

func _ready():
	for menu_button in [$Menu/File]:
		menu_button.get_popup().connect('index_pressed', self, '_on_menu_pressed', [menu_button.get_popup()])

	# TODO: Conditionally load in theme based on Editor or standalone

	path = 'res://dialogue.wol'
	build_nodes()

func build_nodes():
	for node in Compiler.new(path).get_nodes():
		var graph_node = GraphNodeTemplate.duplicate()
		$GraphEdit.add_child(graph_node)
		graph_node.node = node
		graph_node.show()
		graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node, node])

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

func _on_graph_node_input(event, graph_node, node):
	if event is InputEventMouseButton \
			and event.doubleclick and event.button_index == BUTTON_LEFT:
		$HBoxContainer/Editor.open_node(graph_node, node)
		accept_event()
