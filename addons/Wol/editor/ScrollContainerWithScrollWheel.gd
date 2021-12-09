extends ScrollContainer


func _ready():
	connect('gui_input', self, '_on_gui_input')

func _on_gui_input(event):
	if event is InputEventPanGesture:
		scroll_vertical += event.delta.y * .1

	# NOTE: Maybe smooth the scrolling?
	if event is InputEventMouseButton:
		var factor = event.factor if event.factor != 0 else 1.0
		if event.button_index == BUTTON_WHEEL_UP:
			scroll_vertical += 1 * factor
		elif event.button_index == BUTTON_WHEEL_DOWN:
			scroll_vertical -= 1 * factor
