tool
extends Panel

var current_node
var current_graph_node

func _ready():
	hide()
	connect('visibility_changed', self, '_on_visibility_changed')
	$Close.connect('pressed', self, 'close')

func close():
	hide()

func open_node(graph_node, node):
	current_node = node
	current_graph_node = graph_node

	var text_edit = graph_node.get_node('TextEdit')
	text_edit.get_parent().remove_child(text_edit)
	$Content.add_child(text_edit)
	toggle_text_edit(text_edit)
	
	show()
	
	# window_title = node.title

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

func _on_visibility_changed():
	if not visible:
		var text_edit = $Content/TextEdit
		$Content.remove_child(text_edit)
		current_graph_node.add_child(text_edit)
		toggle_text_edit(text_edit)
