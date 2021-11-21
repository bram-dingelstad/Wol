extends Object

const FunctionInfo = preload('res://addons/Wol/core/FunctionInfo.gd')
const Constants = preload('res://addons/Wol/core/Constants.gd')

var functions = {}
var virtual_machine

func get_function(name):
	if functions.has(name):
		return functions[name]
	else :
		printerr('Invalid Function: %s'% name)
		return

func import_library(other):
	Constants.merge_dir(functions, other.functions)

func register_function(name, parameter_count, function, returns_value):
	var functionInfo = FunctionInfo.new(name, parameter_count, function, returns_value)
	functions[name] = functionInfo

func deregister_function(name):
	functions.erase(name)
