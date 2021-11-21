extends Node

const Constants = preload('res://addons/Wol/core/Constants.gd')
const Value = preload('res://addons/Wol/core/Value.gd')

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
var state

var current_node

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
	assert(dialogue_finished_handler.is_valid(), 'Cannot run without a dialogue finished handler (_on_dialogue_finished)')

	state = VmState.new()

#set the node to run
#return true if successeful false if no node
#of that name found
func set_node(name):
	if program == null or program.nodes.size() == 0:
		printerr('Could not load %s : no nodes loaded' % name)
		return false
	
	if not program.nodes.has(name):
		execution_state = Constants.ExecutionState.Stopped
		reset()
		printerr('No node named %s has been found in dialogue, so not loading' % name)
		return false

	current_node = program.nodes[name]
	reset()
	state.current_node_name = name
	node_start_handler.call_func(name)
	return true

func pause():
	execution_state = Constants.ExecutionState.Suspended

func stop():
	execution_state = Constants.ExecutionState.Stopped
	reset()
	current_node = null

func set_selected_option(id):
	if execution_state != Constants.ExecutionState.WaitingForOption:
		printerr('Unable to select option when dialogue not waiting for option')
		return false

	if id < 0 or id >= state.current_options.size():
		printerr('%d is not a valid option!' % id)
		return false

	var destination = state.current_options[id][1]
	state.push_value(destination)
	state.current_options.clear()

	execution_state = Constants.ExecutionState.Suspended
	return true

func reset():
	state = VmState.new()

func get_next_instruction():
	if current_node.instructions.size() - 1 > state.programCounter:
		return current_node.instructions[state.programCounter + 1]
	return

func start():
	if execution_state == Constants.ExecutionState.Stopped:
		execution_state = Constants.ExecutionState.Suspended
		resume()

func resume():
	if current_node == null:
		printerr('Cannot run dialogue with no node selected')
		return false

	if execution_state == Constants.ExecutionState.WaitingForOption:
		printerr('Cannot run while waiting for option')
		return false

	if execution_state == Constants.ExecutionState.Stopped:
		printerr('Dialogue is stopped, explicitely start it before resuming')
		return false

	execution_state = Constants.ExecutionState.Running
	
	#execute instruction until something cool happens
	while execution_state == Constants.ExecutionState.Running:
		var current_instruction = current_node.instructions[state.programCounter]
		run_instruction(current_instruction)
		state.programCounter += 1

		if state.programCounter >= current_node.instructions.size():
			node_finished_handler.call_func(current_node.nodeName)
			execution_state = Constants.ExecutionState.Stopped
			reset()
			dialogue_finished_handler.call_func()

	return true

func find_label_instruction(label):
	if not current_node.labels.has(label):
		printerr('Unknown label:' + label)
		return -1
	return current_node.labels[label]

func run_instruction(instruction):
	match instruction.operation:
		Constants.ByteCode.Label:
			pass

		# Jump to named label
		Constants.ByteCode.JumpTo:
			state.programCounter = find_label_instruction(instruction.operands[0].value) - 1

		Constants.ByteCode.RunLine:
			# Lookup string and give back as line
			var key = instruction.operands[0].value
			var line = program.strings[key]

			# The second operand is the expression count of format function
			# TODO: Add format functions supportk
			if instruction.operands.size() > 1:
				pass

			var return_state = line_handler.call_func(line)
			
			if return_state == Constants.HandlerState.PauseExecution:
				execution_state = Constants.ExecutionState.Suspended
			
		Constants.ByteCode.RunCommand:
			var command_text = instruction.operands[0].value
			var command = Program.Command.new(command_text)

			var return_state = command_handler.call_func(command)
			if return_state == Constants.HandlerState.PauseExecution:
				execution_state = Constants.ExecutionState.Suspended

		Constants.ByteCode.PushString, \
		Constants.ByteCode.PushNumber, \
		Constants.ByteCode.PushBool:
			state.push_value(instruction.operands[0].value)
		Constants.ByteCode.PushNull:
			state.push_value(Value.new(null))

		# Jump to named label if value of stack top is false
		Constants.ByteCode.JumpIfFalse:
			if not state.peek_value().as_bool():
			 state.programCounter = find_label_instruction(instruction.operands[0].value) - 1
				
		# Jump to label whose name is on the stack
		Constants.ByteCode.Jump:
			var destination = state.peek_value().as_string()
			state.programCounter = find_label_instruction(destination) - 1

		Constants.ByteCode.Pop:
			state.pop_value()

		Constants.ByteCode.CallFunc:
			var function_name = instruction.operands[0].value
			var function = libraries.get_function(function_name)
			var expected_parameter_count = function.parameter_count
			var actual_parameter_count = state.pop_value().as_number()

			if expected_parameter_count > 0 \
					and expected_parameter_count != actual_parameter_count:
				var error_data = [function_name, expected_parameter_count, actual_parameter_count]
				printerr('Function "%s" expected %d parameters but got %d instead' % error_data)
				return false

			var result

			if actual_parameter_count == 0:
				result = function.invoke()
			else:
				var params = []
				for _i in range(actual_parameter_count):
					params.push_front(state.pop_value())

				result = function.invoke(params)

			if function.returns_value:
				state.push_value(result)

		Constants.ByteCode.PushVariable:
			var name = instruction.operands[0].value
			var loaded = dialogue.variable_storage.get_value(name)
			state.push_value(loaded)

		Constants.ByteCode.StoreVariable:
			var top = state.peek_value()
			var destination = instruction.operands[0].value
			dialogue.variable_storage.set_value(destination, top)
				
		Constants.ByteCode.Stop:
			node_finished_handler.call_func(current_node.name)
			dialogue_finished_handler.call_func()
			execution_state = Constants.ExecutionState.Stopped
			reset()

		Constants.ByteCode.RunNode:
			var name = ''
			if instruction.operands.size() == 0 or instruction.operands[0].value.empty():
				name = state.peek_value().value()
			else:
				name = instruction.operands[0].value

			var return_state = node_finished_handler.call_func(current_node.name)
			set_node(name)
			state.programCounter -= 1
			if return_state == Constants.HandlerState.PauseExecution:
				execution_state = Constants.ExecutionState.Suspended

		Constants.ByteCode.AddOption:
			var key = instruction.operands[0].value
			var line = program.strings[key]

			# TODO: Add format functions supportk
			if instruction.operands.size() > 2:
				pass
			
			state.current_options.append([line, instruction.operands[1].value])

		Constants.ByteCode.ShowOptions:
			if state.current_options.size() == 0:
				execution_state = Constants.ExecutionState.Stopped
				reset()
				dialogue_finished_handler.call_func()
				return false

			var choices = []
			for option_index in range(state.current_options.size()):
				var option = state.current_options[option_index]
				var line = option[0]
				var destination = option[1]
				choices.append(Program.Option.new(line, option_index, destination))

			execution_state = Constants.ExecutionState.WaitingForOption
			options_handler.call_func(choices)

		_:
			execution_state = Constants.ExecutionState.Stopped
			reset()
			printerr('Unknown Bytecode %s' % instruction.operation)
			return false

	return true

class VmState:
	var current_node_name = ''
	var programCounter = 0
	var current_options = []
	var stack = []

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
