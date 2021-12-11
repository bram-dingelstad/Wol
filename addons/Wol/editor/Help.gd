extends Panel

onready var editor = get_node('../Editor')

func _ready():
	$Tools/Right/Close.connect('pressed', self, 'close')
	connect('gui_input', self, '_on_gui_input')

func close():
	hide()

func _on_gui_input(event):
	if event is InputEventKey \
			and event.pressed and event.scancode == KEY_ESCAPE:
		close()
		editor.grab_focus()
