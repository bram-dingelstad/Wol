extends LineEdit

export var disable_spaces = false

func _ready():
	connect('text_changed', self, '_on_text_changed')

func _on_text_changed(_new_text):
	if disable_spaces and ' ' in text:
		var cursor_position = text.find(' ')
		text = text.replace(' ', '')
		caret_position = cursor_position

		emit_signal('text_changed', text)

