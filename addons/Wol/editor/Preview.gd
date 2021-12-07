extends Panel

var current_graph_node

onready var line_template = $Content/List/LineTemplate
onready var button_template = $Options/List/ButtonTemplate

onready var wol_editor = find_parent('WolEditor')

func _ready():
	hide()
	$Wol.connect('line', self, '_on_line')
	$Wol.connect('options', self, '_on_options')
	$Tools/Right/Close.connect('pressed', self, 'close')

func open_node(graph_node):
	current_graph_node = graph_node

	$Wol.stop()

	for child in $Content/List.get_children():
		if child != line_template and not 'Padding' in child.name:
			$Content/List.remove_child(child)
			child.queue_free()

	for child in $Options/List.get_children():
		if child != button_template:
			$Options/List.remove_child(child)
			child.queue_free()
	
	$Wol.variable_storage = {}
	$Wol.set_program(wol_editor.get_program())
	$Wol.start(current_graph_node.node.title)
	show()

func close():
	hide()
	current_graph_node = null
	$Wol.stop()

func next():
	$Wol.resume()

func _on_line(line):
	var line_node = line_template.duplicate()
	$Content/List.add_child(line_node)
	$Content/List/PaddingBottom.raise()
	line_node.get_node('RichTextLabel').bbcode_text = line.text
	line_node.show()
	yield(get_tree(), 'idle_frame')
	$Content.scroll_vertical = $Content/List.rect_size.y

func _on_options(options):
	for option in options:
		var button = button_template.duplicate()
		$Options/List.add_child(button)

		button.text = option.line.text
		button.connect('pressed', self, '_on_option_pressed', [option])
		button.show()

func _on_option_pressed(option):
	$Wol.select_option(option.id)

	for child in $Options/List.get_children():
		if child != button_template:
			$Options/List.remove_child(child)
			child.queue_free()

func _input(event):
	if visible \
			and ( \
				(event is InputEventMouseButton and event.doubleclick) \
				or (event is InputEventKey and not event.pressed and event.scancode in [KEY_SPACE, KEY_ENTER]) \
			):
		next()
