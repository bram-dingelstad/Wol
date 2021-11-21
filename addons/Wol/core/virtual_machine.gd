extends Node

const Constants = preload('res://addons/Wol/core/constants.gd')
var Value = load('res://addons/Wol/core/value.gd')

const EXECUTION_COMPLETE : String = 'execution_complete_command'

var NULL_VALUE = Value.new(null)

# Function references to handlers
var line_handler
var options_handler
var command_handler
var node_start_handler
var node_finished_handler
var dialogue_finished_handler

var dialogue
var libraries
var program
var _state

var _currentNode

var execution_state = Constants.ExecutionState.Stopped

var string_table = {}

func _init(_dialogue, _libraries):
	dialogue = _dialogue
	libraries = _libraries
	libraries.virtual_machine = self

	line_handler = funcref(dialogue, '_on_line')
	options_handler = funcref(dialogue, '_on_options')
	command_handler = funcref(dialogue, '_on_command')
	node_start_handler = funcref(dialogue, '_on_node_start')
	node_finished_handler = funcref(dialogue, '_on_node_finished')
	dialogue_finished_handler = funcref(dialogue, '_on_dialogue_finished')

	assert(line_handler.is_valid(), 'Cannot run without a line handler (_on_line)')
	assert(options_handler.is_valid(), 'Cannot run without a options handler (_on_options)')
	assert(command_handler.is_valid(), 'Cannot run without a command handler (_on_command)')
	assert(node_start_handler.is_valid(), 'Cannot run without a node start handler (_on_node_start)')
	assert(node_finished_handler.is_valid(), 'Cannot run without a node finished handler (_on_node_finished)')

	_state = VmState.new()

#set the node to run
#return true if successeful false if no node
#of that name found
func set_node(name):
	if program == null || program.nodes.size() == 0:
		printerr('Could not load %s : no nodes loaded' % name)
		return false
	
	if !program.nodes.has(name):
		execution_state = Constants.ExecutionState.Stopped
		reset()
		printerr('No node named %s has been loaded' % name)
		return false

	_currentNode = program.nodes[name]
	reset()
	_state.currentNodeName = name
	node_start_handler.call_func(name)
	return true

func current_node_name()->String:
	return _currentNode.nodeName

func current_node():
	return _currentNode

func pause():
	execution_state = Constants.ExecutionState.Suspended

#stop exectuion
func stop():
	execution_state = Constants.ExecutionState.Stopped
	reset()
	_currentNode = null

#set the currently selected option and
#resume execution if waiting for result
#return false if error
func set_selected_option(id):
	if execution_state != Constants.ExecutionState.WaitingForOption:
		printerr('Unable to select option when dialogue not waiting for option')
		return false

	if id < 0 or id >= _state.currentOptions.size():
		printerr('%d is not a valid option ' % id)
		return false

	var destination = _state.currentOptions[id].value
	_state.push_value(destination)
	_state.currentOptions.clear()

	#no longer waiting for option
	execution_state = Constants.ExecutionState.Suspended
	
	return true

func reset():
	_state = VmState.new()

func get_next_instruction():
	return null if _currentNode.instructions.size() - 1 <= _state.programCounter else _currentNode.instructions[_state.programCounter + 1]

func resume():
	if _currentNode == null:
		printerr('Cannot run dialogue with no node selected')
		return false

	if execution_state == Constants.ExecutionState.WaitingForOption:
		printerr('Cannot run while waiting for option')
		return false
	
	

	execution_state = Constants.ExecutionState.Running
	
	#execute instruction until something cool happens
	while execution_state == Constants.ExecutionState.Running:
		var currentInstruction = _currentNode.instructions[_state.programCounter]

		run_instruction(currentInstruction)
		_state.programCounter += 1

		if _state.programCounter >= _currentNode.instructions.size():
			node_finished_handler.call_func(_currentNode.nodeName)
			execution_state = Constants.ExecutionState.Stopped
			reset()
			dialogue_finished_handler.call_func()

	return true

func find_label_instruction(label:String)->int:
	if !_currentNode.labels.has(label):
		printerr('Unknown label:'+label)
		return -1
	return _currentNode.labels[label]

func run_instruction(instruction)->bool:
	match instruction.operation:
		Constants.ByteCode.Label:
			pass

		Constants.ByteCode.JumpTo:
			#jump to named label
			_state .programCounter = find_label_instruction(instruction.operands[0].value)-1

		Constants.ByteCode.RunLine:
			#look up string from string table
			#pass it to client as line
			var key = instruction.operands[0].value
			
			var line = program.strings[key]

			#the second operand is the expression count
			# of format function
			if instruction.operands.size() > 1:
				pass#add format function support

			var pause = line_handler.call_func(line)
			
			if pause == Constants.HandlerState.PauseExecution:
				execution_state = Constants.ExecutionState.Suspended
			
		Constants.ByteCode.RunCommand:
			var commandText : String = instruction.operands[0].value

			if instruction.operands.size() > 1:
				pass#add format function

			var command = Program.Command.new(commandText)

			var pause = command_handler.call_func(command) as int
			if pause == Constants.HandlerState.PauseExecution:
				execution_state = Constants.ExecutionState.Suspended

		Constants.ByteCode.PushString:
			#push String var to stack
			_state.push_value(instruction.operands[0].value)

		Constants.ByteCode.PushNumber:
			#push number to stack
			_state.push_value(instruction.operands[0].value)

		Constants.ByteCode.PushBool:
			#push boolean to stack
			_state.push_value(instruction.operands[0].value)

		Constants.ByteCode.PushNull:
			#push null t
			_state.push_value(NULL_VALUE)

		Constants.ByteCode.JumpIfFalse:
			#jump to named label if value of stack top is false
			if !_state.peek_value().as_bool():
				_state.programCounter = find_label_instruction(instruction.operands[0].value)-1
				
		Constants.ByteCode.Jump:
			#jump to label whose name is on the stack
			var dest : String = _state.peek_value().as_string()
			_state.programCounter = find_label_instruction(dest)-1

		Constants.ByteCode.Pop:
			#pop value from stack
			_state.pop_value()

		Constants.ByteCode.CallFunc:
			#call function with params on stack
			#push any return value to stack
			var functionName : String = instruction.operands[0].value

			var function = libraries.get_function(functionName)

			var expected_parameter_count : int = function.paramCount
			var actual_parameter_count : int = _state.pop_value().as_number()

			#if function takes in -1 params disregard
			#expect the compiler to have placed the number of params
			#at the top of the stack
			if expected_parameter_count == -1:
				expected_parameter_count = actual_parameter_count

			if expected_parameter_count != actual_parameter_count:
				printerr('Function %s expected %d parameters but got %d instead' %[functionName,
				expected_parameter_count,actual_parameter_count])
				return false

			var result

			if actual_parameter_count == 0:
				result = function.invoke()
			else:
				var params : Array = []#value
				for _i in range(actual_parameter_count):
					params.push_front(_state.pop_value())

				result = function.invoke(params)

			if function.returnsValue:
				_state.push_value(result)

		Constants.ByteCode.PushVariable:
			#get content of variable and push to stack
			var name : String = instruction.operands[0].value
			# TODO: Reimplement variable storage
			var loaded = dialogue.variable_storage.get_value(name)
			_state.push_value(loaded)

		Constants.ByteCode.StoreVariable:
			#store top stack value to variable
			var top = _state.peek_value()
			var destination : String = instruction.operands[0].value
			dialogue.variable_storage.set_value(destination,top)
				
		Constants.ByteCode.Stop:
			#stop execution and repost it
			node_finished_handler.call_func(_currentNode.name)
			dialogue_finished_handler.call_func()
			execution_state = Constants.ExecutionState.Stopped
			reset()

		Constants.ByteCode.RunNode:
			#run a node
			var name : String

			if (instruction.operands.size() == 0 || instruction.operands[0].value.empty()):
				#get string from stack and jump to node with that name
				name = _state.peek_value().value()
			else :
				name = instruction.operands[0].value

			var pause = node_finished_handler.call_func(_currentNode.name)
			set_node(name)
			_state.programCounter-=1
			if pause == Constants.HandlerState.PauseExecution:
				execution_state = Constants.ExecutionState.Suspended

		Constants.ByteCode.AddOption:
			# add an option to current state
			var key = instruction.operands[0].value

			var line = program.strings[key]

			if instruction.operands.size() > 2:
				pass #formated text options
			
			# line to show and node name
			_state.currentOptions.append(SimpleEntry.new(line, instruction.operands[1].value))

		Constants.ByteCode.ShowOptions:
			#show options - stop if none
			if _state.currentOptions.size() == 0:
				execution_state = Constants.ExecutionState.Stopped
				reset()
				dialogue_finished_handler.call_func()
				return false

			#present list of options
			var choices : Array = []#Option
			for optionIndex in range(_state.currentOptions.size()):
				var option : SimpleEntry = _state.currentOptions[optionIndex]
				choices.append(Program.Option.new(option.key, optionIndex, option.value))

			#we cant continue until option chosen
			execution_state = Constants.ExecutionState.WaitingForOption

			#pass the options to the client
			#delegate for them to call
			#when user makes selection

			options_handler.call_func(choices)
		_:
			execution_state = Constants.ExecutionState.Stopped
			reset()
			printerr('Unknown Bytecode %s' % instruction.operation)
			return false

	return true

class VmState:
	var Value = load('res://addons/Wol/core/value.gd')

	var currentNodeName : String
	var programCounter : int = 0
	var currentOptions : Array = []#SimpleEntry
	var stack : Array = [] #Value

	func push_value(value)->void:
		if value is Value:
			stack.push_back(value)
		else:
			stack.push_back(Value.new(value))

	func pop_value():
		return stack.pop_back()

	func peek_value():
		return stack.back()

	func clear_stack():
		stack.clear()

class SimpleEntry:
	var key
	var value

	func _init(_key, _value):
		key = _key
		value = _value
