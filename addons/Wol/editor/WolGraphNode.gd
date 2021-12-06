tool
extends GraphNode

signal recompiled

const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
const Constants = preload('res://addons/Wol/core/Constants.gd')

var node setget set_node

var error_lines = []
var compiler
var program

onready var text_edit = $TextEdit

func _ready():
	connect('offset_changed', self, '_on_offset_changed')
	text_edit.connect('text_changed', self, '_on_text_changed')
	$TextDebounce.connect('timeout', self, '_on_debounce')

func get_connections():
	# NOTE: Program failed to compile
	if not program:
		return []

	var program_node = program.nodes.values().front()
	var connections = []

	# FIXME: Don't rely on checking on 'Label\d'
	var label_check = RegEx.new()
	label_check.compile('^Label\\doption_\\d')

	for instruction in program_node.instructions:
		# NOTE: When next node is explicit
		if instruction.operation == Constants.ByteCode.RunNode:
			if instruction.operands.size() > 0 \
					and instruction.operands.front().value != name:
				connections.append(instruction.operands.front().value)

		# NOTE: When next node is decided through options
		if instruction.operation == Constants.ByteCode.AddOption:
			if instruction.operands.size() == 2 \
					and not label_check.search(instruction.operands[1].value) \
					and instruction.operands[1].value != name:
				connections.append(instruction.operands[1].value)

	return connections

func _on_text_changed():
	$TextDebounce.start(.3)

func _on_debounce():
	text_edit.get_node('ErrorGutter').hide()
	node.body = text_edit.text
	for line in error_lines:
		text_edit.set_line_as_safe(line - 1, false)
	compile()

func _on_offset_changed():
	node.position = offset

func _on_error(message, line_number, _column):
	var error_gutter = text_edit.get_node('ErrorGutter')
	error_gutter.show()
	error_gutter.text = message

	error_lines.append(line_number)

	text_edit.set_line_as_safe(line_number - 1, true)

func set_node(_node):
	node = _node
	title = node.title
	name = node.title
	text_edit.text = node.body
	text_edit.clear_undo_history()
	offset = node.position

	compile()

func compile():
	var text = 'title: %s\n---\n%s\n===' % [node.title, text_edit.text]
	compiler = Compiler.new(null, text, true)
	compiler.connect('error', self, '_on_error')
	program = compiler.compile()

	yield(get_tree(), 'idle_frame')
	emit_signal('recompiled')
