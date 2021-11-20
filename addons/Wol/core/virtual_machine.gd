extends Node
var WolGlobals = load("res://addons/Wol/autoloads/execution_states.gd")

var FunctionInfo = load("res://addons/Wol/core/function_info.gd")
var Value = load("res://addons/Wol/core/value.gd")
var WolProgram = load("res://addons/Wol/core/program/program.gd")
var WolNode = load("res://addons/Wol/core/program/wol_node.gd")
var Instruction = load("res://addons/Wol/core/program/instruction.gd")
var Line = load("res://addons/Wol/core/dialogue/line.gd")
var Command = load("res://addons/Wol/core/dialogue/command.gd")
var Option = load("res://addons/Wol/core/dialogue/option.gd")

const EXECUTION_COMPLETE : String = "execution_complete_command"

var NULL_VALUE = Value.new(null)

# Function references to handlers
var lineHandler
var optionsHandler
var commandHandler
var nodeStartHandler
var nodeCompleteHandler
var dialogueCompleteHandler

var _dialogue
var _program
var _state

var _currentNode

var executionState = WolGlobals.ExecutionState.Stopped

var string_table = {}

func _init(dialogue):
	self._dialogue = dialogue
	_state = VmState.new()

func set_program(program):
	_program = program

#set the node to run
#return true if successeful false if no node
#of that name found
func set_node(name:String) -> bool:
	if _program == null || _program.wolNodes.size() == 0:
		printerr("Could not load %s : no nodes loaded" % name)
		return false
	
	if !_program.wolNodes.has(name):
		executionState = WolGlobals.ExecutionState.Stopped
		reset()
		printerr("No node named %s has been loaded" % name)
		return false

	_dialogue.dlog("Running node %s" % name)

	_currentNode = _program.wolNodes[name]
	reset()
	_state.currentNodeName = name
	nodeStartHandler.call_func(name)
	return true


func current_node_name()->String:
	return _currentNode.nodeName

func current_node():
	return _currentNode

func pause():
	executionState = WolGlobals.ExecutionState.Suspended

#stop exectuion
func stop():
	executionState = WolGlobals.ExecutionState.Stopped
	reset()
	_currentNode = null

#set the currently selected option and
#resume execution if waiting for result
#return false if error
func set_selected_option(id):
	if executionState != WolGlobals.ExecutionState.WaitingForOption:
		printerr("Unable to select option when dialogue not waiting for option")
		return false

	if id < 0 || id >= _state.currentOptions.size():
		printerr("%d is not a valid option "%id)
		return false

	var destination = _state.currentOptions[id].value
	_state.push_value(destination)
	_state.currentOptions.clear()

	#no longer waiting for option
	executionState = WolGlobals.ExecutionState.Suspended
	
	return true

func has_options()->bool:
	return _state.currentOptions.size() > 0

func reset():
	_state = VmState.new()

#continue execution
func resume()->bool:
	if _currentNode == null :
		printerr("Cannot run dialogue with no node selected")
		return false
	if executionState == WolGlobals.ExecutionState.WaitingForOption:
		printerr("Cannot run while waiting for option")
		return false
	
	if lineHandler == null :
		printerr("Cannot run without a lineHandler")
		return false
	
	if optionsHandler == null :
		printerr("Cannot run without an optionsHandler")	
		return false

	if commandHandler == null :
		printerr("Cannot run without an commandHandler")	
		return false
	if nodeStartHandler == null :
		printerr("Cannot run without a nodeStartHandler")	
		return false
	if nodeCompleteHandler == null :
		printerr("Cannot run without an nodeCompleteHandler")	
		return false


	executionState = WolGlobals.ExecutionState.Running
	
	#execute instruction until something cool happens
	while executionState == WolGlobals.ExecutionState.Running:
		var currentInstruction = _currentNode.instructions[_state.programCounter]

		run_instruction(currentInstruction)
		_state.programCounter+=1

		if _state.programCounter >= _currentNode.instructions.size():
			nodeCompleteHandler.call_func(_currentNode.nodeName)
			executionState = WolGlobals.ExecutionState.Stopped
			reset()
			dialogueCompleteHandler.call_func()
			_dialogue.dlog("Run Complete")

	return true

func find_label_instruction(label:String)->int:
	if !_currentNode.labels.has(label):
		printerr("Unknown label:"+label)
		return -1
	return _currentNode.labels[label]

func run_instruction(instruction)->bool:
	match instruction.operation:
		WolGlobals.ByteCode.Label:
			pass

		WolGlobals.ByteCode.JumpTo:
			#jump to named label
			_state .programCounter = find_label_instruction(instruction.operands[0].value)-1

		WolGlobals.ByteCode.RunLine:
			#look up string from string table
			#pass it to client as line
			var key = instruction.operands[0].value

			var line = Line.new(key)

			#the second operand is the expression count
			# of format function
			if instruction.operands.size() > 1:
				pass#add format function support

			var pause : int = lineHandler.call_func(line)
			

			if pause == WolGlobals.HandlerState.PauseExecution:
				executionState = WolGlobals.ExecutionState.Suspended
			
		WolGlobals.ByteCode.RunCommand:
			var commandText : String = instruction.operands[0].value

			if instruction.operands.size() > 1:
				pass#add format function

			var command = Command.new(commandText)

			var pause = commandHandler.call_func(command) as int
			if pause == WolGlobals.HandlerState.PauseExecution:
				executionState = WolGlobals.ExecutionState.Suspended

		WolGlobals.ByteCode.PushString:
			#push String var to stack
			_state.push_value(instruction.operands[0].value)

		WolGlobals.ByteCode.PushNumber:
			#push number to stack
			_state.push_value(instruction.operands[0].value)

		WolGlobals.ByteCode.PushBool:
			#push boolean to stack
			_state.push_value(instruction.operands[0].value)

		WolGlobals.ByteCode.PushNull:
			#push null t
			_state.push_value(NULL_VALUE)

		WolGlobals.ByteCode.JumpIfFalse:
			#jump to named label if value of stack top is false
			if !_state.peek_value().as_bool():
				_state.programCounter = find_label_instruction(instruction.operands[0].value)-1
				
		WolGlobals.ByteCode.Jump:
			#jump to label whose name is on the stack
			var dest : String = _state.peek_value().as_string()
			_state.programCounter = find_label_instruction(dest)-1

		WolGlobals.ByteCode.Pop:
			#pop value from stack
			_state.pop_value()

		WolGlobals.ByteCode.CallFunc:
			#call function with params on stack
			#push any return value to stack
			var functionName : String = instruction.operands[0].value

			var function = _dialogue.library.get_function(functionName)

			var expectedParamCount : int = function.paramCount
			var actualParamCount : int = _state.pop_value().as_number()

			#if function takes in -1 params disregard
			#expect the compiler to have placed the number of params
			#at the top of the stack
			if expectedParamCount == -1:
				expectedParamCount = actualParamCount

			if expectedParamCount != actualParamCount:
				printerr("Function %s expected %d parameters but got %d instead" %[functionName,
				expectedParamCount,actualParamCount])
				return false

			var result

			if actualParamCount == 0:
				result = function.invoke()
			else:
				var params : Array = []#value
				for i in range(actualParamCount):
					params.push_front(_state.pop_value())

				result = function.invoke(params)

			if function.returnsValue:
				_state.push_value(result)

		WolGlobals.ByteCode.PushVariable:
			#get content of variable and push to stack
			var name : String = instruction.operands[0].value
			var loaded = _dialogue._variableStorage.get_value(name)
			_state.push_value(loaded)
		WolGlobals.ByteCode.StoreVariable:
			#store top stack value to variable
			var top = _state.peek_value()
			var destination : String = instruction.operands[0].value
			_dialogue._variableStorage.set_value(destination,top)
				
		WolGlobals.ByteCode.Stop:
			#stop execution and repost it
			nodeCompleteHandler.call_func(_currentNode.nodeName)
			dialogueCompleteHandler.call_func()
			executionState = WolGlobals.ExecutionState.Stopped
			reset()

		WolGlobals.ByteCode.RunNode:
			#run a node
			var name : String

			if (instruction.operands.size() == 0 || instruction.operands[0].value.empty()):
				#get string from stack and jump to node with that name
				name = _state.peek_value().value()
			else :
				name = instruction.operands[0].value

			var pause = nodeCompleteHandler.call_func(_currentNode.nodeName)
			set_node(name)
			_state.programCounter-=1
			if pause == WolGlobals.HandlerState.PauseExecution:
				executionState = WolGlobals.ExecutionState.Suspended

		WolGlobals.ByteCode.AddOption:
			# add an option to current state
			var key = instruction.operands[0].value

			var line  = Line.new(key, _program.wolStrings[key])

			if instruction.operands.size() > 2:
				pass #formated text options
			
			# line to show and node name
			_state.currentOptions.append(SimpleEntry.new(line,instruction.operands[1].value))
		WolGlobals.ByteCode.ShowOptions:
			#show options - stop if none
			if _state.currentOptions.size() == 0:
				executionState = WolGlobals.ExecutionState.Stopped
				reset()
				dialogueCompleteHandler.call_func()
				return false

			#present list of options
			var choices : Array = []#Option
			for optionIndex in range(_state.currentOptions.size()):
				var option : SimpleEntry = _state.currentOptions[optionIndex]
				choices.append(Option.new(option.key, optionIndex, option.value))

			#we cant continue until option chosen
			executionState = WolGlobals.ExecutionState.WaitingForOption

			#pass the options to the client
			#delegate for them to call
			#when user makes selection

			optionsHandler.call_func(choices)
		_:
			#bytecode messed up woopsise
			executionState = WolGlobals.ExecutionState.Stopped
			reset()
			printerr("Unknown Bytecode %s "%instruction.operation)
			return false

	return true

class VmState:
	var Value = load("res://addons/Wol/core/value.gd")

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
	var value : String

	func _init(key,value:String):
		self.key = key
		self.value = value
