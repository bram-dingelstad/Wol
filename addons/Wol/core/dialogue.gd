extends Node

const Constants = preload('res://addons/Wol/core/constants.gd')
const VirtualMachine = preload('res://addons/Wol/core/virtual_machine.gd')
const Value = preload('res://addons/Wol/core/value.gd')

var _variableStorage

var _program
var library

var _vm
var _visitedNodeCount = {}

func _init(variableStorage):
	_variableStorage = variableStorage

func is_active():
	return get_exec_state() != Constants.ExecutionState.Stopped

func set_selected_option(option):
	_vm.set_selected_option(option)

func set_node(name = 'Start'):
	_vm.set_node(name)

func start():
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

func node_exists(name):
	return _program.nodes.has(name)

func set_program(program):
	_program = program
	_vm.set_program(_program)
	_vm.reset()

func get_vm():
	return _vm


