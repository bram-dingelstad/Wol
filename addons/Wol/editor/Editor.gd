tool
extends Panel

var current_graph_node

onready var preview = get_node('../Preview')
onready var wol_editor = find_parent('WolEditor')

func _ready():
	hide()
	connect('visibility_changed', self, '_on_visibility_changed')
	$Tools/Left/Play.connect('pressed', self, '_on_play')
	$Tools/Right/Close.connect('pressed', self, 'close')
	$Tools/Right/Delete.connect('pressed', self, '_on_delete_pressed')

func close():
	hide()
	preview.close()

func open_node(graph_node):
	current_graph_node = graph_node

	var text_edit = graph_node.get_node('TextEdit')
	text_edit.get_parent().remove_child(text_edit)
	$Content.add_child(text_edit)
	toggle_text_edit(text_edit)
	
	$Tools/Left/Title.disconnect('text_changed', self, '_on_title_changed')
	$Tools/Left/Title.text = graph_node.node.title
	$Tools/Left/Title.connect('text_changed', self, '_on_title_changed')
	
	show()

func toggle_text_edit(text_edit):
	text_edit.anchor_left = 0
	text_edit.anchor_top = 0
	text_edit.anchor_bottom = 1
	text_edit.anchor_right = 1
	text_edit.margin_left = 0
	text_edit.margin_right = 0
	text_edit.margin_bottom = 0
	text_edit.margin_top = 0
	text_edit.mouse_filter = MOUSE_FILTER_STOP if text_edit.get_parent().name == 'Content' else MOUSE_FILTER_IGNORE

	text_edit.deselect()

	for property in [
		'highlight_current_line',
		'show_line_numbers',
		'draw_tabs',
		'smooth_scrolling',
		'wrap_enabled',
		'minimap_draw'
	]:
		text_edit.set(property, not text_edit.get(property))

func _on_play():
	preview.open_node(current_graph_node)

func _on_delete_pressed():
	wol_editor.confirm_delete_node(current_graph_node)

func _on_title_changed():
	current_graph_node.node.title = $HBoxContainer/TextEdit.text
	current_graph_node.compile()

func _on_visibility_changed():
	if not visible:
		var text_edit = $Content/TextEdit
		$Content.remove_child(text_edit)
		current_graph_node.add_child(text_edit)
		toggle_text_edit(text_edit)
