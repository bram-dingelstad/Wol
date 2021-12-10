tool
extends Control

const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
onready var GraphNodeTemplate = $GraphNodeTemplate

var path
var selected_node
var saved_all_changes = false
var mouse_panning = false

onready var original_delete_node_dialog = $DeleteNodeDialog.dialog_text
onready var inside_godot_editor = not get_tree().current_scene and Engine.editor_hint

# Standalone
# TODO: Add confirm window for creating new file if working on another
# TODO: Make arrow keys / WASD select next node
# TODO: Make ENTER key open a editor
# TODO: Add comprehensive Help in a dialog
# TODO: Add scrolling ability to a node when focussing a node

# Godot Editor
# FIXME: Make all parts of the code "tool"s and safekeep its execution while in editora
# FIXME: Hide console when viewing Wol main screen

# Web version
# TODO: Test out web version
# TODO: Make web loading / saving work

# Nice to have
# TODO: Make deleting undo-able
# TODO: Try to replicate positioning from existing Yarn Editor
# TODO: Implement settings
# TODO: Add more settings (like custom theme)
# TODO: Make shortcut for opening preview (CMD+P)
# TODO: More messages in preview for different things (command, start, stop, choices, log)

func _ready():
	for menu_button in [$Menu/File]:
		menu_button.get_popup().connect('index_pressed', self, '_on_menu_pressed', [menu_button.get_popup()])

	$Menu/Settings.connect('pressed', self, 'show_settings')
	$Menu/About.connect('pressed', self, 'show_about')
	$Menu/Help.connect('pressed', self, 'show_help')

	$GraphEdit.connect('gui_input', self, '_on_graph_edit_input')
	$GraphEdit.connect('node_selected', self, '_on_node_selected', [true])
	$GraphEdit.connect('node_unselected', self, '_on_node_selected', [false])
	$GraphEdit.connect('_end_node_move', self, 'reconnect_nodes')

	$DeleteNodeDialog.connect('confirmed', self, 'delete_node')
	$HelpDialog/HSplitContainer/Right.connect('meta_clicked', self, '_on_url_clicked')

	path = 'res://dialogue.wol'
	build_nodes()

	if inside_godot_editor:
		theme = null

		for child in $HBoxContainer.get_children():
			child.size_flags_horizontal = SIZE_EXPAND_FILL
		
		$HBoxContainer.set('custom_constants/seperation', 0)

func create_node(position = Vector2.ZERO):
	var graph_node = GraphNodeTemplate.duplicate()
	$GraphEdit.add_child(graph_node)

	var node = {
		'title': 'NewNode',
		'body': 'Wol: Hello world',
		'position': position
	}

	graph_node.connect('recompiled', self, '_on_graph_node_recompiled', [graph_node])
	graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node])

	graph_node.node = node
	graph_node.show()

func delete_node(node = selected_node):
	if $HBoxContainer/Editor.visible:
		$HBoxContainer/Editor.close()
	$GraphEdit.remove_child(node)
	node.queue_free()

func confirm_delete_node(node = selected_node):
	selected_node = node
	$DeleteNodeDialog.dialog_text = original_delete_node_dialog % selected_node.name
	$DeleteNodeDialog.popup()

func build_nodes():
	for node in Compiler.new(path).get_nodes():
		var graph_node = GraphNodeTemplate.duplicate()
		$GraphEdit.add_child(graph_node)

		graph_node.connect('recompiled', self, '_on_graph_node_recompiled', [graph_node])
		graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node])

		graph_node.node = node
		graph_node.show()

func get_program():
	return Compiler.new(null, serialize_to_file(), true).compile()

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

func show_settings():
	$SettingsDialog.popup()

func show_about():
	$AboutDialog.popup()

func show_help():
	$HelpDialog.popup()

func _on_url_clicked(url):
	OS.shell_open(url)
	
func _on_menu_pressed(index, node):
	match node.get_item_text(index):
		'New':
			new()
		'Save':
			save_as(path)
		'Save as...':
			save_as()
		'Open':
			open()

func _on_graph_node_recompiled(_graph_node):
	reconnect_nodes()

func reconnect_nodes():
	$GraphEdit.clear_connections()

	# TODO: Implement setting for determining style
	if true:
		connect_nodes_single_style()
	else:
		connect_nodes_godot_style()

func connect_nodes_single_style():
	for graph_node in $GraphEdit.get_children():
		if not graph_node is GraphNode:
			continue

		graph_node.set_slot_enabled_left(0, false)
		graph_node.set_slot_enabled_right(0, false)

	for graph_node in $GraphEdit.get_children():
		if not graph_node is GraphNode:
			continue

		var connections = graph_node.get_connections()

		for connection in connections:
			if not $GraphEdit.has_node(connection):
				continue

			var other_graph_node = $GraphEdit.get_node(connection)
			var destination_is_to_the_right = graph_node.offset.x <= other_graph_node.offset.x

			if destination_is_to_the_right:
				graph_node.set_slot_enabled_right(0, true)
				graph_node.set_slot_type_right(0, 1)

				other_graph_node.set_slot_enabled_left(0, true)
				other_graph_node.set_slot_type_left(0, 1)
				
				$GraphEdit.connect_node(graph_node.name, 0, other_graph_node.name, 0)
			else:
				graph_node.set_slot_enabled_left(0, true)
				graph_node.set_slot_type_left(0, 1)

				other_graph_node.set_slot_enabled_right(0, true)
				other_graph_node.set_slot_type_right(0, 1)
				
				$GraphEdit.connect_node(other_graph_node.name, 0, graph_node.name, 0)

func connect_nodes_godot_style():
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

func move_focus(event):
	var current_focussed
	var first_node
	for node in $GraphEdit.get_children():
		if node is GraphNode:
			if not first_node:
				first_node = node
			if node.selected:
				current_focussed = node

	if not current_focussed:
		current_focussed = first_node

	var vector = Vector2.RIGHT
	match event.scancode:
		KEY_D, KEY_RIGHT:
			pass # Defaults to right

		KEY_A, KEY_LEFT:
			vector = vector.rotated(PI)


func _on_graph_node_input(event, graph_node):
	if event is InputEventMouseButton \
			and event.doubleclick and event.button_index == BUTTON_LEFT:
		$HBoxContainer/Editor.open_node(graph_node)
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

	if event is InputEventMouseButton \
			and event.button_index == BUTTON_RIGHT:
		mouse_panning = event.pressed

	if event is InputEventMouseMotion and mouse_panning:
		$GraphEdit.scroll_offset -= event.relative
	
	if event is InputEventKey and not event.pressed:
		move_focus(event)

func _input(event):
	if not visible:
		return

	if event is InputEventKey \
			and not event.pressed and event.physical_scancode == KEY_DELETE \
			and selected_node \
			and not $HBoxContainer/Editor.visible:
		confirm_delete_node()

	if event is InputEventKey:
		var combination = OS.get_scancode_string(event.get_physical_scancode_with_modifiers())

		if OS.get_name() == 'OSX':
			combination = combination.replace('Command', 'Control')

		match combination:
			'Control+N':
				new()
			'Control+S':
				save_as(path)
			'Shift+Control+S':
				save_as()
			'Control+O':
				open()

