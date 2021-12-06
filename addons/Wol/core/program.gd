extends Object

const Constants = preload('res://addons/Wol/core/Constants.gd')

var name = ''
var filename = ''
var strings = {}
var nodes = {}

class Line:
	var text = ''
	var node_name = ''
	var line_number = -1
	var file_name = ''
	var implicit = false
	var substitutions = []
	var meta = []

	func _init(_text, _node_name, _line_number, _file_name, _implicit, _meta):
		text = _text
		node_name = _node_name
		file_name = _file_name
		implicit = _implicit
		meta = _meta

	func clone():
		return get_script().new(text, node_name, line_number, file_name, implicit, meta)

	func _to_string():
		return '%s:%d: "%s"' % [file_name.get_file(), line_number, text]

class Option:
	var line
	var id = -1
	var destination = ''

	func _init(_line, _id, _destination):
		line = _line
		id = _id
		destination = _destination

	func clone():
		return get_script().new(self)

class Command:
	var command = ''

	func _init(_command):
		command = _command

class WolNode:
	var name = ''
	var instructions = []
	var labels = {}
	var tags = []
	var source_id = ''

	func _init(other = null):
		if other != null and other.get_script() == self.get_script():
			name = other.name
			instructions += other.instructions
			for key in other.labels.keys():
				labels[key] = other.labels[key]
			tags += other.tags
			source_id = other.source_id

	func equals(other):
		if other.get_script() != get_script():
			return false
		if other.name != name:
			return false
		if other.instructions != instructions:
			return false
		if other.labels != labels:
			return false
		if other.source_id != source_id:
			return false
		return true

	func _to_string():
		return "WolNode[%s:%s]"  % [name, source_id]

# TODO: Make this make sense
class Operand:
	enum ValueType {
		None,
		StringValue,
		BooleanValue,
		FloatValue
	}

	var value
	var type

	func _init(_value):
		if typeof(_value) == TYPE_OBJECT and _value.get_script() == get_script():
			set_value(_value.value)
		else:
			set_value(_value)

	func set_value(_value):
		match typeof(_value):
			TYPE_REAL,TYPE_INT:
				set_number(_value)
			TYPE_BOOL:
				set_boolean(_value)
			TYPE_STRING:
				set_string(_value)

	func set_boolean(_value):
		value = _value
		type = ValueType.BooleanValue
		return self

	func set_string(_value):
		value = _value
		type = ValueType.StringValue
		return self

	func set_number(_value):
		value = _value
		type = ValueType.FloatValue
		return self

	func clear_value():
		type = ValueType.None
		value = null

	func clone():
		return get_script().new(self)

	func _to_string():
		return "Operand[%s:%s]" % [type, value]

class Instruction:
	var operation = -1
	var operands = []

	func _init(other = null):
		if other != null and other.get_script() == self.get_script():
			self.operation = other.operation
			self.operands += other.operands

	func _to_string():
		return Constants.bytecode_name(operation) + ':' + operands as String

