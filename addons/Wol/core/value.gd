extends Object

const Constants = preload('res://addons/Wol/core/Constants.gd')

const NULL_STRING = 'null'
const FALSE_STRING = 'false'
const TRUE_STRING = 'true'
const NANI = 'NaN'

var type = Constants.ValueType.Nullean
var number = 0
var string = ''
var variable = ''
var boolean = false

func _init(value = NANI):
	if typeof(value) == TYPE_OBJECT && value.get_script() == self.get_script():
		if value.type == Constants.ValueType.Variable:
			self.type = value.type
			self.variable = value.variable
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
	if value == null || (typeof(value) == TYPE_STRING && value == NANI):
		type = Constants.ValueType.Nullean
		return

	match typeof(value):
		TYPE_INT,TYPE_REAL:
			type = Constants.ValueType.Number
			number = value
		TYPE_STRING:
			type = Constants.ValueType.Str
			string = value
		TYPE_BOOL:
			type = Constants.ValueType.Boolean
			boolean = value

#operations >>

#addition
func add(other):
	if self.type == Constants.ValueType.Str || other.type == Constants.ValueType.Str:
		return get_script().new('%s%s'%[self.value(),other.value()])
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return get_script().new(self.number + other.number)
	return null

func equals(other)->bool:
	if other.get_script() != self.get_script():
		return false
	if other.value() != self.value():
		return false
	return true #refine this

#subtract
func sub(other):
	if self.type == Constants.ValueType.Str || other.type == Constants.ValueType.Str:
		return get_script().new(str(value()).replace(str(other.value()),''))
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return get_script().new(self.number - other.number)
	return null

#multiply
func mult(other):
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return get_script().new(self.number * other.number)
	return null

#division
func div(other):
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return get_script().new(self.number / other.number)
	return null

#modulus
func mod(other):
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return get_script().new(self.number % other.number)
	return null

func negative():
	if self.type == Constants.ValueType.Number:
		return get_script().new(-self.number)
	return null

#greater than other
func greater(other)->bool:
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return self.number > other.number
	return false

#less than other
func less(other)->bool:
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return self.number < other.number
	return false

#greater than or equal to other
func geq(other)->bool:
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return self.number > other.number || self.equals(other)
	return false

#lesser than or equal to other
func leq(other)->bool:
	if self.type == Constants.ValueType.Number && other.type == Constants.ValueType.Number:
		return self.number < other.number || self.equals(other)
	return false

func _to_string():
	return 'value(type[%s]: %s)' % [type,value()]


