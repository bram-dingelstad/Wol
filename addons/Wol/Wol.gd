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

const Constants = preload('res://addons/Wol/core/constants.gd')
const WolCompiler = preload('res://addons/Wol/core/compiler/compiler.gd')
const WolDialogue = preload('res://addons/Wol/core/dialogue.gd')

export(String, FILE, '*.wol,*.yarn') var path setget set_path
export(String) var start_node = 'Start'
export(bool) var auto_start = false
export(NodePath) var variable_storage_path
export var auto_show_options = true

onready var variable_storage = get_node(variable_storage_path)

var program

var dialogue

func _ready():
	if Engine.editor_hint:
		return

	if not variable_storage:
		variable_storage = Node.new()
		variable_storage.name = 'VariableStorage'
		variable_storage.set_script(load('res://addons/Wol/core/variable_storage.gd'))
		add_child(variable_storage)

	if auto_start:
		start()

func init_dialogue():
	# FIXME: Move visited count to variable storage
	var existing_state
	if dialogue != null:
		existing_state = dialogue._visitedNodeCount

	dialogue = WolDialogue.new(variable_storage)

	# FIXME: Remove these lines
	if existing_state:
		dialogue._visitedNodeCount = existing_state

	dialogue.get_vm().lineHandler = funcref(self, '_handle_line')
	dialogue.get_vm().optionsHandler = funcref(self, '_handle_options')
	dialogue.get_vm().commandHandler = funcref(self, '_handle_command')
	dialogue.get_vm().nodeCompleteHandler = funcref(self, '_handle_node_complete')
	dialogue.get_vm().dialogueCompleteHandler = funcref(self, '_handle_dialogue_complete')
	dialogue.get_vm().nodeStartHandler = funcref(self, '_handle_node_start')

	dialogue.set_program(program)

func set_path(_path):
	path = _path

	if not Engine.editor_hint:
		var compiler = WolCompiler.new(path)
		program = compiler.compile()

func _handle_line(line):
	call_deferred('emit_signal', 'line', line)
	if auto_show_options \
			and dialogue.get_vm().get_next_instruction().operation == Constants.ByteCode.AddOption:
		return Constants.HandlerState.ContinueExecution
	else:
		return Constants.HandlerState.PauseExecution

func _handle_command(command):
	call_deferred('emit_signal', 'command', command)

	if get_signal_connection_list('command').size() > 0:
		return Constants.HandlerState.PauseExecution
	else:
		return Constants.HandlerState.ContinueExecution

func _handle_options(options):
	call_deferred('emit_signal', 'options', options)
	return Constants.HandlerState.PauseExecution

func _handle_dialogue_complete():
	emit_signal('finished')

func _handle_node_start(node):
	emit_signal('node_started', node)
	dialogue.resume()

	if !dialogue._visitedNodeCount.has(node):
		dialogue._visitedNodeCount[node] = 1
	else:
		dialogue._visitedNodeCount[node] += 1

func _handle_node_complete(node):
	emit_signal('node_finished', node)
	return Constants.HandlerState.ContinueExecution

func select_option(id):
	dialogue.get_vm().set_selected_option(id)
	resume()

func pause():
	dialogue.call_deferred('pause')

func start(node = start_node):
	init_dialogue()
	emit_signal('started')

	dialogue.set_node(node)
	dialogue.start()

func resume():
	dialogue.call_deferred('resume')
