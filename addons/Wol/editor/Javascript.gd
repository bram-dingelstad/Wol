extends Control

var open_callback

func _ready():
	if OS.get_name() != 'HTML5':
		return queue_free()

	open_callback = JavaScript.create_callback(self, 'open')

	JavaScript.eval("""
	window.glue = {
		register: function(callback) {
			document.querySelector('html').ondrop = function(event) {
				console.log('Dropped something!', arguments)
				if (event.dataTransfer.files.length) {
					var file = event.dataTransfer.files[0]
					var extension = file.name.split('.').pop()

					if (['wol', 'yarn'].indexOf(extension) === -1)
						return console.error('Dropped file wasn\\'t a .yarn or .wol file')

					file.text().then(
						function (text) {
							callback(text, file.name)
						}
					)
				} else {
					console.error('Dropped something that wasn\\'t a file!')
				}
			}
		}
	}
""", true)
	
	JavaScript.get_interface('glue').register(open_callback)
	var file_menu = get_parent().find_node('Menu').get_node('File').get_popup()
	file_menu.remove_item(2) # Save as
	file_menu.remove_item(1) # Open

func open(arguments):
	var text = arguments[0]
	var filename = arguments[1]
	var file = File.new()

	var path = 'user://%s' % filename
	file.open(path, File.WRITE)
	file.store_string(text)
	file.close()
	
	get_parent().open(path)

	$Label.hide()

func save_as(file_path):
	if not file_path:
		file_path = 'UnnamedDialogue.wol'

	JavaScript.download_buffer(get_parent().serialize_to_file().to_utf8(), file_path.get_file())
