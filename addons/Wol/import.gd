tool
extends EditorImportPlugin


func get_importer_name():
	return 'wol.yarnandwol'

func get_visible_name():
	return 'Wol / Yarn file'

func get_recognized_extensions():
	return ['yarn', 'wol']

func get_save_extension():
	return 'res'

func get_resource_type():
	return 'Resource'

func get_preset_count():
	return 0

func get_preset_name(_preset):
	return 'None'

func get_import_options(_preset):
	return []

func get_option_visibility(option, options):
	return false

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
		return err

	var wol_file = WolFile.new(file.get_as_text())
	file.close()
	return ResourceSaver.save('%s.res' % save_path, Resource.new())

# TODO: Globalize this and also make it the resource to be picked with the Wol node
class WolFile:
	extends Resource

	var content = ''

	func _init(_content):
		content = _content

