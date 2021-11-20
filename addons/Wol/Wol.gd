tool
extends Node

signal node_started(node)
signal line(line)
signal options(options)
signal command(command)
signal node_completed(node)

signal started
signal finished

const WolCompiler = preload('res://addons/Wol/core/compiler/compiler.gd')
const WolDialogue = preload('res://addons/Wol/core/dialogue.gd')

export(String, FILE, '*.wol,*.yarn') var path setget set_path
export(String) var start_node = 'Start'
export(bool) var auto_start = false
export(NodePath) var variable_storage_path

onready var variable_storage = get_node(variable_storage_path)

var program

var dialogue
var running = false

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
	var file = File.new()
	file.open(_path, File.READ)
	var source = file.get_as_text()
	file.close()
	program = WolCompiler.compile_string(source, _path)
	path = _path

func _handle_line(line):
	var id = line.id
	var string = program.wolStrings[id]
	call_deferred('emit_signal', 'line', string)
	return WolGlobals.HandlerState.PauseExecution

func _handle_command(command):
	call_deferred('emit_signal', 'command', command)

	if get_signal_connection_list('command').size() > 0:
		return WolGlobals.HandlerState.PauseExecution
	else:
		return WolGlobals.HandlerState.ContinueExecution

func _handle_options(options):
	call_deferred('emit_signal' ,'options', options)
	return WolGlobals.HandlerState.PauseExecution

func _handle_dialogue_complete():
	emit_signal('finished')
	running = false

func _handle_node_start(node):
	emit_signal('node_started', node)
	print('node started')
	dialogue.resume()

	if !dialogue._visitedNodeCount.has(node):
		dialogue._visitedNodeCount[node] = 1
	else:
		dialogue._visitedNodeCount[node] += 1

	print(dialogue._visitedNodeCount)

func _handle_node_complete(node):
	emit_signal('node_completed', node)
	running = false
	return WolGlobals.HandlerState.ContinueExecution

func select_option(id):
	dialogue.get_vm().set_selected_option(id)

func pause():
	dialogue.call_deferred('pause')

func start(node = start_node):
	if running:
		return

	init_dialogue()
	emit_signal('started')

	running = true
	dialogue.set_node(node)

func resume():
	dialogue.call_deferred('resume')
