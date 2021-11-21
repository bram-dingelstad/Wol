tool
extends Node
class_name Wol

signal node_started(node)
signal node_finished(node)

# NOTE: Warning is ignored because they get call_deferred
# warning-ignore:unused_signal
signal line(line)
# warning-ignore:unused_signal
signal options(options)
# warning-ignore:unused_signal
signal command(command)

signal started
signal finished

const Constants = preload('res://addons/Wol/core/Constants.gd')
const WolCompiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
const WolLibrary = preload('res://addons/Wol/core/Library.gd')
const VirtualMachine = preload('res://addons/Wol/core/VirtualMachine.gd')
const StandardLibrary = preload('res://addons/Wol/core/StandardLibrary.gd')

export(String, FILE, '*.wol,*.yarn') var path setget set_path
export(String) var start_node = 'Start'
export(bool) var auto_start = false
export(NodePath) var variable_storage_path
export var auto_show_options = true

onready var variable_storage = get_node(variable_storage_path)

var virtual_machine

func _ready():
	if Engine.editor_hint:
		return
	
	var libraries = WolLibrary.new()
	libraries.import_library(StandardLibrary.new())
	virtual_machine = VirtualMachine.new(self, libraries)

	set_path(path)

	if not variable_storage:
		variable_storage = Node.new()
		variable_storage.name = 'VariableStorage'
		variable_storage.set_script(load('res://addons/Wol/core/variable_storage.gd'))
		add_child(variable_storage)

	if auto_start:
		start()

func set_path(_path):
	path = _path

	if not Engine.editor_hint and virtual_machine:
		var compiler = WolCompiler.new(path)
		virtual_machine.program = compiler.compile()

func _on_line(line):
	call_deferred('emit_signal', 'line', line)
	if auto_show_options \
			and virtual_machine.get_next_instruction().operation == Constants.ByteCode.AddOption:
		return Constants.HandlerState.ContinueExecution
	else:
		return Constants.HandlerState.PauseExecution

func _on_command(command):
	call_deferred('emit_signal', 'command', command)

	if get_signal_connection_list('command').size() > 0:
		return Constants.HandlerState.PauseExecution
	else:
		return Constants.HandlerState.ContinueExecution

func _on_options(options):
	call_deferred('emit_signal', 'options', options)
	return Constants.HandlerState.PauseExecution

func _on_dialogue_finished():
	emit_signal('finished')

func _on_node_start(node):
	emit_signal('node_started', node)

func _on_node_finished(node):
	emit_signal('node_finished', node)
	return Constants.HandlerState.ContinueExecution

func select_option(id):
	virtual_machine.set_selected_option(id)
	resume()

func pause():
	virtual_machine.call_deferred('pause')

func start(node = start_node):
	emit_signal('started')

	virtual_machine.set_node(node)
	virtual_machine.start()

func resume():
	virtual_machine.call_deferred('resume')
