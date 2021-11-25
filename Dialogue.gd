extends Control

func _ready():
	$RichTextLabel/Logo.hide()
	$VBoxContainer/ButtonTemplate.hide()

func continue_dialogue():
	if $Tween.is_active():
		$Tween.remove_all()
		$RichTextLabel.percent_visible = 1.0	
		return

	$Wol.resume()

func _on_Wol_line(line):
	$RichTextLabel.bbcode_text = line.text

	$Tween.remove_all()
	$Tween.interpolate_property(
		$RichTextLabel,
		'percent_visible',
		.0,
		1.0,
		.02 * line.text.length()
	)

	$Tween.start()

func _on_Wol_options(options):
	var button_template = $VBoxContainer/ButtonTemplate
	
	for option in options:
		var button = button_template.duplicate()
		button.text = option.line.text
		button.name = 'Option%d' % option.id

		$VBoxContainer.add_child(button)
		button.connect('pressed', self, '_on_option_selected', [option])
		button.show()

func _on_option_selected(option):
	$Wol.select_option(option.id)

	for child in $VBoxContainer.get_children():
		if not 'Template' in child.name:
			child.queue_free()

func _on_Wol_finished():
	$RichTextLabel.text = ''

func _input(event):
	if event is InputEventKey and event.scancode == KEY_ENTER and event.pressed:
		continue_dialogue()
