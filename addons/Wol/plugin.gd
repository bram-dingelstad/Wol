tool
extends EditorPlugin

const WolEditor = preload('res://addons/Wol/editor/WolEditor.tscn')

var wol_editor_instance

func _enter_tree():
	add_custom_type(
		'Wol',
		'Node',
		load('res://addons/Wol/Wol.gd'),
		load('res://addons/Wol/icon-white.svg')
	)

	wol_editor_instance = WolEditor.instance()
	get_editor_interface().get_editor_viewport().add_child(wol_editor_instance)

	make_visible(false)

func make_visible(visible):
	if wol_editor_instance:
		wol_editor_instance.visible = visible

func _exit_tree():
	remove_custom_type('Wol')

	if wol_editor_instance:
		wol_editor_instance.queue_free()

func has_main_screen():
	return true

func get_plugin_name():
	return 'Wol'

func get_plugin_icon():
	var icon = ImageTexture.new()
	var image = Image.new()
	image.load('res://addons/Wol/icon-white.svg')
	image.resize(34, 34)
	icon.create_from_image(image)
	return icon
