tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton(
		'YarnGlobals',
		'res://addons/Wol/autoloads/execution_states.gd'
	)

	add_custom_type(
		'Wol',
		'Node',
		load('res://addons/Wol/yarn_runner.gd'),
		load('res://addons/Wol/assets/icon.png')
	)


func _exit_tree():
	remove_autoload_singleton('YarnGlobals')
	remove_custom_type('Wol')
