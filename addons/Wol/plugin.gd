tool
extends EditorPlugin

# const WolEditor = preload('res://addons/Wol/editor/WolEditor.tscn')

var wol_editor_instance
var import_plugin

func _enter_tree():
	add_custom_type(
		'Wol',
		'Node',
		load('res://addons/Wol/Wol.gd'),
		load('res://addons/Wol/icon-white.svg')
	)

	# wol_editor_instance = WolEditor.instance()
	# get_editor_interface().get_editor_viewport().add_child(wol_editor_instance)

	import_plugin = preload('res://addons/Wol/import.gd').new()
	add_import_plugin(import_plugin)

	make_visible(false)
	
	call_deferred('move_button')
	
	
func move_button():
	var buttons = get_editor_interface().get_base_control()
	var path = [0, 0, 2]
	for child_number in path:
		if buttons.get_child_count() > child_number:
			buttons = buttons.get_child(child_number)

	if buttons.has_node('AssetLib'):
		buttons.get_node('AssetLib').raise()

func make_visible(visible):
	if wol_editor_instance:
		wol_editor_instance.visible = visible

func _exit_tree():
	remove_custom_type('Wol')

	remove_import_plugin(import_plugin)
	import_plugin = null

	# if wol_editor_instance:
	# 	wol_editor_instance.queue_free()

# func has_main_screen():
# 	return true

func get_plugin_name():
	return 'Wol'

func get_plugin_icon():
	# FIXME: Change this code so it doesn't show a warning on activation
	var icon = ImageTexture.new()
	var image = Image.new()
	image.load('res://addons/Wol/icon-white.svg')
	image.resize(34, 34)
	icon.create_from_image(image)
	return icon
