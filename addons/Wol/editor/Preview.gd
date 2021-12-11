tool
extends Panel

var current_graph_node

onready var line_template = $Content/List/LineTemplate
onready var button_template = $Options/List/ButtonTemplate

onready var wol_editor = find_parent('WolEditor')
onready var editor = get_node('../Editor')

func _ready():
	hide()
	$Wol.connect('line', self, '_on_line')
	$Wol.connect('options', self, '_on_options')
	$Wol.connect('command', self, '_on_command')
	$Wol.connect('finished', self, '_on_finished')

	connect('gui_input', self, '_on_gui_input')

	$Tools/Left/Next.connect('pressed', self, 'next')
	$Tools/Left/Restart.connect('pressed', self, 'restart')
	$Tools/Right/Close.connect('pressed', self, 'close')

	for child in $Tools/Left/Protagonist.get_children():
		if child is VScrollBar:
			child.rect_scale = Vector2.ZERO

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

# TODO: Implement default protagonist setting
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

	if editor.visible:
		editor.grab_focus()

func next():
	$Wol.resume()

func restart():
	$Wol.stop()

	yield(get_tree(), 'idle_frame')
	clear_chat()
	yield(get_tree(), 'idle_frame')

	add_message('Restarting dialogue...')
	$Wol.start(current_graph_node.node.title)

func add_message(text, align = 'system', color = Color(0, 0, 0, 0)):
	var line_node = line_template.duplicate()
	$Content/List.add_child(line_node)
	$Content/List/PaddingBottom.raise()

	match align:
		'left':
			line_node.get_node('PaddingRight').size_flags_horizontal = SIZE_EXPAND_FILL
		'right':
			line_node.get_node('PaddingLeft').size_flags_horizontal = SIZE_EXPAND_FILL
		'center':
			line_node.get_node('PaddingRight').size_flags_horizontal = SIZE_EXPAND_FILL
			line_node.get_node('PaddingLeft').size_flags_horizontal = SIZE_EXPAND_FILL
		'system':
			line_node.get_node('PaddingRight').size_flags_horizontal = SIZE_FILL
			line_node.get_node('PaddingLeft').size_flags_horizontal = SIZE_FILL
			text = '[color=gray][center][i]%s[/i][/center][/color]' % text
			
	line_node.get_node('RichTextLabel').bbcode_text = text

	var panel = line_node.get_node('RichTextLabel/Panel') \
			.get('custom_styles/panel') \
			.duplicate()

	panel.bg_color = color
	line_node.get_node('RichTextLabel/Panel').set('custom_styles/panel', panel)
	line_node.show()
	
	yield(get_tree(), 'idle_frame')
	$Content.scroll_vertical = $Content/List.rect_size.y

func _on_line(line):
	var align = 'left' if get_protagonist(line) == $Tools/Left/Protagonist.text else 'right'
	var color
	if get_protagonist(line):
		color = Color(hash(get_protagonist(line)))
	else:
		color = Color.darkgray

	add_message(line.text, align, color)

func _on_command(command):
	add_message('Executed command "%s"' % command.command)
	$Wol.resume()

func _on_options(options):
	add_message('Being shown %d options' % options.size())

	for option in options:
		var button = button_template.duplicate()
		$Options/List.add_child(button)

		button.text = option.line.text
		button.connect('pressed', self, '_on_option_pressed', [option])
		button.show()

func _on_option_pressed(option):
	add_message('Selected option "%s"' % option.line.text)
	$Wol.select_option(option.id)

	for child in $Options/List.get_children():
		if child != button_template:
			$Options/List.remove_child(child)
			child.queue_free()

	grab_focus()

func _on_finished():
	add_message('Dialogue stopped.')

func _on_gui_input(event):
	if visible:
		if event is InputEventMouseButton and event.doubleclick:
			next()

		if event is InputEventMouseButton and event.pressed:
			grab_focus()

		if event is InputEventKey and event.scancode == KEY_ESCAPE:
			close()

func _input(event):
	if visible and has_focus() and event is InputEventKey and not event.pressed and event.scancode in [KEY_SPACE, KEY_ENTER]:
		next()
