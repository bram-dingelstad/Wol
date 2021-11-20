extends Object

const Operand = preload("res://addons/Wol/core/program/operand.gd")

var operation : int #bytcode
var operands : Array #Operands

func _init(other=null):
	if other != null && other.get_script() == self.get_script():
		self.operation = other.operation
		self.operands += other.operands

func dump(program,library)->String:
	return "InstructionInformation:NotImplemented"

func _to_string():
	return WolGlobals.bytecode_name(operation) + ':' + operands as String
