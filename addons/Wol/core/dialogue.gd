extends Node

const DEFAULT_START = 'Start'

const Constants = preload('res://addons/Wol/core/constants.gd')
const StandardLibrary = preload('res://addons/Wol/core/libraries/standard.gd')
const VirtualMachine = preload('res://addons/Wol/core/virtual_machine.gd')
const WolLibrary = preload('res://addons/Wol/core/library.gd')
const Value = preload('res://addons/Wol/core/value.gd')

var _variableStorage

var _program
var library

var _vm

var _visitedNodeCount = {}

var executionComplete

func _init(variableStorage):
	_variableStorage = variableStorage
	_vm = VirtualMachine.new(self)
	library = WolLibrary.new()
	executionComplete = false

	# import the standard library
	# this contains math constants, operations and checks
	library.import_library(StandardLibrary.new())#FIX
	
	#add a function to lib that checks if node is visited
	library.register_function('visited', -1, funcref(self, 'is_node_visited'), true)
	
	#add function to lib that gets the node visit count
	library.register_function('visit_count', -1, funcref(self, 'node_visit_count'), true)

func is_active():
	return get_exec_state() != Constants.ExecutionState.Stopped

#gets the current execution state of the virtual machine
func get_exec_state():
	return _vm.executionState

func set_selected_option(option):
	_vm.set_selected_option(option)

func set_node(name = DEFAULT_START):
	_vm.set_node(name)

func start():
	print('got here')
	if _vm.executionState == Constants.ExecutionState.Stopped:
		_vm.resume()

func resume():
	if _vm.executionState == Constants.ExecutionState.Running \
			or _vm.executionState == Constants.ExecutionState.Stopped:
		return
	_vm.resume()

func pause():
	_vm.pause()

func stop():
	_vm.stop()

func get_all_nodes():
	return _program.nodes.keys()

func current_node():
	return _vm.get_current()

func get_node_id(name):
	if _program.nodes.size() == 0:
		return ''
	if _program.nodes.has(name):
		return 'id:'+name
	else:
		return ''

func unloadAll(clear_visited:bool = true):
	if clear_visited :
		_visitedNodeCount.clear()
	_program = null

func dump()->String:
	return _program.dump(library)

func node_exists(name:String)->bool:
	return _program.nodes.has(name)

func set_program(program):
	_program = program
	_vm.set_program(_program)
	_vm.reset()

func get_program():
	return _program

func get_vm():
	return _vm

func is_node_visited(node = _vm.current_node_name()):
	return node_visit_count(node) > 0

func node_visit_count(node = _vm.current_node_name()):
	if node is Value:
		node = _program.strings[node.value()].text

	var visitCount : int = 0
	if _visitedNodeCount.has(node):
		visitCount = _visitedNodeCount[node]


	print('visit count for %s is %d' % [node, visitCount])

	return visitCount

func get_visited_nodes():
	return _visitedNodeCount.keys()

func set_visited_nodes(visitedList):
	_visitedNodeCount.clear()
	for string in visitedList:
		_visitedNodeCount[string] = 1
