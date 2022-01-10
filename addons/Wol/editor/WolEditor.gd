tool
extends Control

const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
onready var GraphNodeTemplate = $GraphNodeTemplate

var path
var saved_all_changes = false
var last_save
var mouse_panning = false
var focus_pan = Vector2.ZERO

onready var original_delete_node_dialog = $DeleteNodeDialog.dialog_text
onready var original_unsaved_dialog = $UnsavedDialog.dialog_text
onready var inside_godot_editor = not get_tree().current_scene and Engine.editor_hint

# Godot Editor
# FIXME: Make all parts of the code "tool"s and safekeep its execution while in editor
# FIXME: Hide console when viewing Wol main screen

# Web version
# TODO: Test out web version
# TODO: Make web loading / saving work

# Nice to have
# TODO: Make deleting undo-able
# TODO: Try to replicate positioning from existing Yarn Editor
# TODO: Implement settings
# TODO: Add more settings (like custom theme)
# TODO: Add HSplits instead of HBoxContainer in the editor

func _ready():
	for menu_button in [$Menu/File]:
		menu_button.get_popup().connect('index_pressed', self, '_on_menu_pressed', [menu_button.get_popup()])

	$Menu/Settings.connect('pressed', self, 'show_settings')
	$Menu/About.connect('pressed', self, 'show_about')
	$Menu/Help.connect('pressed', self, 'show_help')
	$Menu/AuthorNotice.connect('pressed', self, '_on_url_clicked', ['https://twitter.com/bram_dingelstad'])

	$GraphEdit.connect('gui_input', self, '_on_graph_edit_input')
	$GraphEdit.connect('node_selected', self, '_on_node_selected', [true])
	$GraphEdit.connect('node_unselected', self, '_on_node_selected', [false])
	$GraphEdit.connect('_end_node_move', self, 'reconnect_nodes')

	$HBoxContainer/Editor.connect('closed', self, '_on_editor_closed')

	$DeleteNodeDialog.connect('confirmed', self, 'delete_node')
	$HelpDialog/HelpSplit/Right.connect('meta_clicked', self, '_on_url_clicked')

	$UnsavedDialog.add_button('Cancel', false, 'cancel')
	$UnsavedDialog.add_button('Don\'t Save', false, 'dont_save')
	$UnsavedDialog.add_button('Save & Close', true, 'save_and_close')
	$UnsavedDialog.get_cancel().hide()
	$UnsavedDialog.get_ok().hide()

	$GraphEdit.get_zoom_hbox().anchor_right = 1
	$GraphEdit.get_zoom_hbox().anchor_left = 1
	$GraphEdit.get_zoom_hbox().anchor_bottom = 0
	$GraphEdit.get_zoom_hbox().anchor_top = 0
	$GraphEdit.get_zoom_hbox().margin_left = -$GraphEdit.get_zoom_hbox().rect_size.x - 18

	var line_edit_density = $GraphEdit.get_zoom_hbox().get_node('@@24/@@22')
	if line_edit_density is LineEdit:
		line_edit_density.focus_mode = FOCUS_CLICK

	if inside_godot_editor:
		theme = null

		for child in $HBoxContainer.get_children():
			child.size_flags_horizontal = SIZE_EXPAND_FILL
		
		$HBoxContainer.set('custom_constants/seperation', 0)

	update_title()

func create_node(position = Vector2.ZERO):
	var graph_node = GraphNodeTemplate.duplicate()
	$GraphEdit.add_child(graph_node)

	var node = {
		'title': 'NewNode',
		'body': 'Here begins your new adventure!',
		'position': position
	}

	graph_node.connect('recompiled', self, '_on_graph_node_recompiled', [graph_node])
	graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node])

	graph_node.node = node
	graph_node.show()

func delete_node(node = get_selected_graph_node()):
	if $HBoxContainer/Editor.visible:
		$HBoxContainer/Editor.close()
	$GraphEdit.remove_child(node)
	node.queue_free()
	reconnect_nodes()

func confirm_delete_node(node = get_selected_graph_node()):
	$DeleteNodeDialog.dialog_text = original_delete_node_dialog % node.name
	$DeleteNodeDialog.popup()

func center_node_on_screen(node):
	var start = $GraphEdit.scroll_offset
	var zoom = $GraphEdit.zoom

	# FIXME : Calculate it manually rather than weird hack
	$GraphEdit.zoom = 1
	$GraphEdit.scroll_offset = node.center - ($GraphEdit.rect_size / 2)
	$GraphEdit.zoom = zoom

	$Tween.interpolate_property(
		$GraphEdit,
		'scroll_offset',
		start,
		$GraphEdit.scroll_offset,
		.5,
		$Tween.TRANS_QUART,
		$Tween.EASE_OUT
	)

	$Tween.start()

func build_nodes():
	for node in Compiler.new(path).get_nodes():
		var graph_node = GraphNodeTemplate.duplicate()
		$GraphEdit.add_child(graph_node)

		graph_node.connect('recompiled', self, '_on_graph_node_recompiled', [graph_node])
		graph_node.connect('gui_input', self, '_on_graph_node_input', [graph_node])

		graph_node.node = node
		graph_node.show()

	last_save = serialize_to_file()

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
	if $Javascript:
		$Javascript.save_as(file_path)
	else:
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

	saved_all_changes = true
	last_save = serialize_to_file()
	update_title()

func open(file_path = ''):
	if file_path.empty():
		$FileDialog.mode = $FileDialog.MODE_OPEN_FILE
		# TODO: Set up path based on context (Godot editor, standalone or web)
		$FileDialog.popup_centered()
		path = yield($FileDialog, 'file_selected')
		if not path:
			return
	else:
		path = file_path

	for node in $GraphEdit.get_children():
		if node is GraphNode:
			$GraphEdit.remove_child(node)
			node.queue_free()

	yield(get_tree(), 'idle_frame')
	build_nodes()

func new():
	if not saved_all_changes:
		$UnsavedDialog.popup()
		$UnsavedDialog.dialog_text = original_unsaved_dialog % path

		var result = yield($UnsavedDialog, 'custom_action')
		$UnsavedDialog.hide()
		match result:
			'save_and_close':
				save_as(path)
			'cancel':
				return
			'dont_save':
				pass # Continue normal execution

	for node in $GraphEdit.get_children():
		if node is GraphNode:
			$GraphEdit.remove_child(node)
			node.queue_free()

	path = null
	last_save = null
	reconnect_nodes()
	update_title()

func show_settings():
	$SettingsDialog.popup()

func show_about():
	$AboutDialog.popup()

func show_help():
	var help = find_node('HelpSplit')
	help.get_parent().remove_child(help)

	if $HBoxContainer/Editor.visible:
		$HBoxContainer/Help/Content.add_child(help)
		$HBoxContainer/Help.show()
		$HBoxContainer/Help.grab_focus()
	else:
		$HelpDialog.add_child(help)
		$HelpDialog.popup()

	help.set_owner(get_tree().current_scene)

func reconnect_nodes():
	$GraphEdit.clear_connections()

	# TODO: Implement setting for determining style
	if true:
		connect_nodes_single_style()
	else:
		connect_nodes_godot_style()

	# NOTE: This gets executed a lot on changes, so check if there are any changes
	saved_all_changes = last_save and last_save == serialize_to_file()
	update_title()

	if $Javascript:
		$Javascript/Label.visible = get_node_count() == 0

func get_node_count():
	var count = 0
	for graph_node in $GraphEdit.get_children():
		if graph_node is GraphNode:
			count += 1
	
	return count

func update_title():
	var filename = 'Unnamed file' if not path else path.get_file()
	var unsaved = '' if saved_all_changes else '*'
	OS.set_window_title('%s%s - Wol Editor' % [filename, unsaved])

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

func get_selected_graph_node():
	var current_focussed
	for node in $GraphEdit.get_children():
		if node is GraphNode:
			if node.selected:
				current_focussed = node

	return current_focussed

func move_focus():
	var current_focussed = get_selected_graph_node()
	var nodes = []
	for node in $GraphEdit.get_children():
		if node is GraphNode:
			nodes.append(node)
				
	# FIXME: Make this based on current offset
	if not current_focussed:
		current_focussed = nodes.back()
		$GraphEdit.set_selected(current_focussed)
		current_focussed.grab_focus()
		center_node_on_screen(current_focussed)
		return

	var closest
	for node in nodes:
		if node == current_focussed:
			continue

		if not closest or \
			closest.center.distance_to(current_focussed.center + focus_pan) \
			> node.center.distance_to(current_focussed.center + focus_pan):
			closest = node

	if closest:
		$GraphEdit.set_selected(closest)
		closest.grab_focus()

	focus_pan = null

func _on_editor_closed():
	get_selected_graph_node().grab_focus()

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

func _on_graph_node_input(event, graph_node):
	var double_clicked = event is InputEventMouseButton \
			and event.doubleclick and event.button_index == BUTTON_LEFT


	if double_clicked:
		$HBoxContainer/Editor.open_node(graph_node)
		accept_event()

func _on_graph_edit_input(event):
	if event is InputEventMouseButton \
			and event.doubleclick and event.button_index == BUTTON_LEFT:
		create_node(event.global_position + $GraphEdit.scroll_offset)

	if event is InputEventMouseButton \
			and event.button_index == BUTTON_RIGHT:
		mouse_panning = event.pressed

	if event is InputEventMouseMotion and mouse_panning:
		$GraphEdit.scroll_offset -= event.relative


func _input(event):
	if not visible:
		return

	if event is InputEventKey \
			and not event.pressed and event.physical_scancode == KEY_DELETE \
			and get_selected_graph_node() \
			and not $HBoxContainer/Editor.visible:
		confirm_delete_node()

	var selected_node = get_selected_graph_node()
	if selected_node and selected_node.has_focus() and event is InputEventKey \
			and not event.pressed and event.scancode == KEY_ENTER:
		$HBoxContainer/Editor.open_node(selected_node)
		accept_event()

	if selected_node and event is InputEventKey \
		and not event.pressed and event.scancode == KEY_F:
		center_node_on_screen(selected_node)


	if event is InputEventKey:
		var combination = OS.get_scancode_string(event.get_physical_scancode_with_modifiers())

		if OS.get_name() == 'OSX':
			combination = combination.replace('Command', 'Control')

		match combination:
			'Control+N':
				return new()
			'Control+S':
				return save_as(path)
			'Shift+Control+S':
				return save_as()
			'Control+O':
				return open()
		
		if not $HBoxContainer/Editor.visible:
			if event.pressed:
				focus_pan = Input.get_vector('ui_left', 'ui_right', 'ui_up', 'ui_down') * 500
			elif focus_pan:
				move_focus()
