tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		'Wol',
		'Node',
		load('res://addons/Wol/Wol.gd'),
		load('res://addons/Wol/assets/icon.png')
	)


func _exit_tree():
	remove_custom_type('Wol')
