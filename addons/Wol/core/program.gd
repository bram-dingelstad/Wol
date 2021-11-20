extends Object
class_name Program

const Constants = preload('res://addons/Wol/core/constants.gd')

var name = ''
var strings = {}
var nodes = {}

class Line:
	var text = ''
	var node_name = ''
	var line_number = -1
	var file_name = ''
	var implicit = false
	var meta = []

	func _init(text, node_name, line_number, file_name, implicit, meta):
		self.text = text
		self.node_name = node_name
		self.file_name = file_name
		self.implicit = implicit
		self.meta = meta

class Option:
	var line
	var id = -1
	var destination = ''

	func _init(line, id, destination):
		self.line = line
		self.id = id
		self.destination = destination

class Command:
	var command = ''

	func _init(command):
		self.command = command

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
		if other.get_script() != self.get_script():
			return false
		if other.name != self.name:
			return false
		if other.instructions != self.instructions:
			return false
		if other.label != self.label:
			return false
		if other.sourceId != self.sourceId:
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

	func _init(value):
		if typeof(value) == TYPE_OBJECT and value.get_script() == self.get_script():
			set_value(value.value)
		else:
			set_value(value)

	func set_value(value):
		match typeof(value):
			TYPE_REAL,TYPE_INT:
				set_number(value)
			TYPE_BOOL:
				set_boolean(value)
			TYPE_STRING:
				set_string(value)

	func set_boolean(value):
		_value(value)
		type = ValueType.BooleanValue
		return self

	func set_string(value):
		_value(value)
		type = ValueType.StringValue
		return self

	func set_number(value):
		_value(value)
		type = ValueType.FloatValue
		return self

	func clear_value():
		type = ValueType.None
		value = null

	func clone():
		return get_script().new(self)

	func _to_string():
		return "Operand[%s:%s]" % [type, value]

	func _value(value):
		self.value = value

class Instruction:
	var operation = -1
	var operands = []

	func _init(other = null):
		if other != null and other.get_script() == self.get_script():
			self.operation = other.operation
			self.operands += other.operands

	func dump(program, library):
		return "InstructionInformation:NotImplemented"

	func _to_string():
		return Constants.bytecode_name(operation) + ':' + operands as String

