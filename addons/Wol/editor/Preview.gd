tool
extends Panel

var current_graph_node

onready var line_template = $Content/List/LineTemplate
onready var button_template = $Options/List/ButtonTemplate

onready var wol_editor = find_parent('WolEditor')

func _ready():
	hide()
	$Wol.connect('line', self, '_on_line')
	$Wol.connect('options', self, '_on_options')

	connect('gui_input', self, '_on_gui_input')

	$Tools/Left/Next.connect('pressed', self, 'next')
	$Tools/Left/Restart.connect('pressed', self, 'restart')
	$Tools/Right/Close.connect('pressed', self, 'close')

func open_node(graph_node):
	current_graph_node = graph_node

	$Wol.stop()

	yield(get_tree(), 'idle_frame')

	clear_chat()

	$Tools/Left/Protagonist.text = guess_protagonist()
	
	$Wol.variable_storage = {}
	$Wol.set_program(wol_editor.get_program())

	yield(get_tree(), 'idle_frame')

	$Wol.start(current_graph_node.node.title)

	show()
	grab_focus()

func clear_chat():
	for child in $Content/List.get_children():
		if child != line_template and not 'Padding' in child.name:
			$Content/List.remove_child(child)
			child.queue_free()

	for child in $Options/List.get_children():
		if child != button_template:
			$Options/List.remove_child(child)
			child.queue_free()


func guess_protagonist():
	var protagonist = 'You'
	var wol_node = wol_editor.get_program().nodes[current_graph_node.node.title]

	for line in wol_node.get_lines():
		if get_protagonist(line):
			protagonist = get_protagonist(line)
			if protagonist == 'You':
				break
		
	return protagonist

func get_protagonist(line):
	if ':' in line.text and line.text.find(':') < 30:
		return line.text.split(':')[0]
	return

func close():
	hide()
	current_graph_node = null
	$Wol.stop()

func next():
	$Wol.resume()

func restart():
	$Wol.stop()

	yield(get_tree(), 'idle_frame')

	clear_chat()

	yield(get_tree(), 'idle_frame')

	$Wol.start(current_graph_node.node.title)

func _on_line(line):
	var line_node = line_template.duplicate()
	$Content/List.add_child(line_node)
	$Content/List/PaddingBottom.raise()

	# TODO: Add hash() based color from speaker
	line_node.get_node('RichTextLabel').bbcode_text = line.text

	var padding_node = 'PaddingRight' if get_protagonist(line) == $Tools/Left/Protagonist.text else 'PaddingLeft'
	line_node.get_node(padding_node).size_flags_horizontal = SIZE_EXPAND_FILL
	var panel = line_node.get_node('RichTextLabel/Panel').get('custom_styles/panel').duplicate()
	panel.bg_color = Color(hash(get_protagonist(line)))
	line_node.get_node('RichTextLabel/Panel').set('custom_styles/panel', panel)

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

func _on_gui_input(event):
	if visible:
		if event is InputEventMouseButton and event.doubleclick:
			next()

		if event is InputEventMouseButton and event.pressed:
			grab_focus()

func _input(event):
	if visible and has_focus() and event is InputEventKey and not event.pressed and event.scancode in [KEY_SPACE, KEY_ENTER]:
		next()
