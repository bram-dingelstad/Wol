extends Control

func _ready():
	pass

func continue_dialogue():
	if $Tween.is_active():
		$Tween.remove_all()
		$RichTextLabel.percent_visible = 1.0	
		return

	$Wol.resume()

func _on_Wol_line(line):
	print(var2str(line))
	$RichTextLabel.text = line.text

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
	prints('got some options', options)

func _input(event):
	if event is InputEventKey and event.scancode == KEY_ENTER and event.pressed:
		print('Pressed enter!')
		continue_dialogue()
