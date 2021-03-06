extends Object

const Value = preload("res://addons/Wol/core/Value.gd")

var name = ''
# NOTE: -1 means variable arguments
var parameter_count = 0
var function
var returns_value = false

func _init(_name, _parameter_count, _function = null, _returns_value = false):
	name = _name
	parameter_count = _parameter_count
	function = _function
	returns_value = _returns_value

func invoke(parameters = []):
	var length = 0
	if parameters != null:
		length = parameters.size()

	if check_parameter_count(length):
		if returns_value:
			var return_value
			if length > 0:
				return_value = function.call_funcv(parameters)
			else:
				return_value = function.call_func()

			if return_value is Value:
				return return_value
			else:
				return Value.new(return_value)
		else:
			if length > 0:
				function.call_funcv(parameters)
			else :
				function.call_func()
	return null

func check_parameter_count(_parameter_count):
	return parameter_count == _parameter_count or parameter_count == -1
