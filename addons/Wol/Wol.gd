tool
extends Node

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

export(String, FILE, '*.wol,*.yarn') var path setget set_path

export var starting_node = 'Start'
export var auto_start = false
export var auto_show_options = true
export var auto_substitute = true

export(Dictionary) var variable_storage = {}

const Constants = preload('res://addons/Wol/core/Constants.gd')
const Compiler = preload('res://addons/Wol/core/compiler/Compiler.gd')
const Library = preload('res://addons/Wol/core/Library.gd')
const VirtualMachine = preload('res://addons/Wol/core/VirtualMachine.gd')
const StandardLibrary = preload('res://addons/Wol/core/StandardLibrary.gd')

var virtual_machine
var running = false

func _ready():
	if Engine.editor_hint:
		return
	
	var libraries = Library.new()
	virtual_machine = VirtualMachine.new(self, libraries)

	libraries.import_library(StandardLibrary.new())

	set_path(path)

	if auto_start:
		start()

func set_path(_path):
	path = _path

	if not Engine.editor_hint and virtual_machine and not path.empty():
		var compiler = Compiler.new(path)
		virtual_machine.program = compiler.compile()

func set_program(program):
	virtual_machine.program = program

func _on_line(line):
	if auto_substitute:
		var index = 0
		for substitute in line.substitutions:
			line.text = line.text.replace('{%d}' % index, substitute)
			index += 1
	
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
	running = false
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

func is_blocked():
	return virtual_machine.execution_state == Constants.ExecutionState.WaitingForOption

func start(node = starting_node):
	running = true
	virtual_machine.set_node(node)
	virtual_machine.start()
	emit_signal('started')

func stop():
	if running:
		virtual_machine.call_deferred('stop')
	running = false

func resume():
	virtual_machine.call_deferred('resume')
