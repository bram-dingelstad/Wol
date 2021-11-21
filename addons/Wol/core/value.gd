extends Object

const Constants = preload('res://addons/Wol/core/Constants.gd')

const NANI = 'NaN'

var type = Constants.ValueType.Nullean
var number = 0
var string = ''
var variable = ''
var boolean = false

func _init(value = NANI):
	if typeof(value) == TYPE_OBJECT and value.get_script() == get_script():
		if value.type == Constants.ValueType.Variable:
			type = value.type
			variable = value.variable
	else:
		set_value(value)

func value():
	match type:
		Constants.ValueType.Number:
			return number
		Constants.ValueType.Str:
			return string
		Constants.ValueType.Boolean:
			return boolean
		Constants.ValueType.Variable:
			return variable
	return null

func as_bool():
	match type:
		Constants.ValueType.Number:
			return number != 0
		Constants.ValueType.Str:
			return !string.empty()
		Constants.ValueType.Boolean:
			return boolean
	return false

func as_string():
	return '%s' % value()

func as_number():
	match type:
		Constants.ValueType.Number:
			return number
		Constants.ValueType.Str:
			return float(string)
		Constants.ValueType.Boolean:
			return 0.0 if !boolean else 1.0
	return .0

func set_value(value):
	if value == null or (typeof(value) == TYPE_STRING and value == NANI):
		type = Constants.ValueType.Nullean
		return

	match typeof(value):
		TYPE_INT, TYPE_REAL:
			type = Constants.ValueType.Number
			number = value
		TYPE_STRING:
			type = Constants.ValueType.Str
			string = value
		TYPE_BOOL:
			type = Constants.ValueType.Boolean
			boolean = value

func add(other):
	if type == Constants.ValueType.Str or other.type == Constants.ValueType.Str:
		return get_script().new('%s%s' % [value(), other.value()])
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return get_script().new(number + other.number)
	return null

func equals(other):
	if other.get_script() != get_script():
		return false
	if other.value() != value():
		return false
	# TODO: Add more equality cases
	return true

func sub(other):
	if type == Constants.ValueType.Str or other.type == Constants.ValueType.Str:
		return get_script().new(str(value()).replace(str(other.value()),''))
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return get_script().new(number - other.number)
	return null

func mult(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return get_script().new(number * other.number)
	return null

func div(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return get_script().new(number / other.number)
	return null

func mod(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return get_script().new(number % other.number)
	return null

func negative():
	if type == Constants.ValueType.Number:
		return get_script().new(-number)
	return null

func greater(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return number > other.number
	return false

func less(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return number < other.number
	return false

func geq(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return number > other.number or equals(other)
	return false

func leq(other):
	if type == Constants.ValueType.Number and other.type == Constants.ValueType.Number:
		return number < other.number or equals(other)
	return false

func _to_string():
	return 'value(type[%s]: %s)' % [type,value()]


