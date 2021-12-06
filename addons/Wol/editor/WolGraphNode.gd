tool
extends GraphNode

const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')

var node setget set_node

onready var text_edit = $TextEdit

func _ready():
	connect('offset_changed', self, '_on_offset_changed')
	text_edit.connect('text_changed', self, '_on_text_changed')
	$TextDebounce.connect('timeout', self, '_on_debounce')

func _on_text_changed():
	$TextDebounce.start(.3)

func _on_debounce():
	text_edit.get_node('ErrorGutter').hide()
	node.body = text_edit.text
	compile()

func _on_offset_changed():
	node.position = offset

func _on_error(message, _line_number, _column):
	var error_gutter = text_edit.get_node('ErrorGutter')
	error_gutter.show()
	error_gutter.text = message

	# TODO: Highlight line based on line number and column

func set_node(_node):
	node = _node
	title = node.title
	text_edit.text = node.body
	text_edit.clear_undo_history()
	offset = node.position

	compile()

func compile():
	var text = '---\n%s\n===' % text_edit.text
	var compiler = Compiler.new(null, text, true)
	compiler.connect('error', self, '_on_error')
	compiler.compile()
