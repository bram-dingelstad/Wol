extends Node2D

var current_dialogue

func _ready():
	$Sally/DialogueStarter.connect('body_entered', self, '_on_player_near_dialogue', [$Sally, true])
	$Sally/DialogueStarter.connect('body_exited', self, '_on_player_near_dialogue', [$Sally, false])
	$Ship/DialogueStarter.connect('body_entered', self, '_on_player_near_dialogue', [$Ship, true])
	$Ship/DialogueStarter.connect('body_exited', self, '_on_player_near_dialogue', [$Ship, false])

func _on_player_near_dialogue(_player, node, entered):
	print('body entered?', entered)
	if entered:
		current_dialogue = node.name
	else:
		current_dialogue = null

func _process(_delta):
	if Input.is_action_just_released('ui_accept') and current_dialogue and not $Dialogue/Wol.running:
		print(current_dialogue)
		$Dialogue/Wol.starting_node = current_dialogue
		$Dialogue/Wol.path = 'res://ExampleDialogue/%s.yarn' % current_dialogue
		$Dialogue/Wol.start()
		print($Dialogue/Wol.variable_storage)
