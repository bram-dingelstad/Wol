tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton(
		'WolGlobals',
		'res://addons/Wol/autoloads/execution_states.gd'
	)

	add_custom_type(
		'Wol',
		'Node',
		load('res://addons/Wol/Wol.gd'),
		load('res://addons/Wol/assets/icon.png')
	)


func _exit_tree():
	remove_autoload_singleton('WolGlobals')
	remove_custom_type('Wol')
