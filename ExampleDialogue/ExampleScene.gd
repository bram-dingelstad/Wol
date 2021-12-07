extends Node2D

var current_dialogue

func _ready():
	$Sally/DialogueStarter.connect('body_entered', self, '_on_player_near_dialogue', [$Sally, true])
	$Sally/DialogueStarter.connect('body_exited', self, '_on_player_near_dialogue', [$Sally, false])
	$Ship/DialogueStarter.connect('body_entered', self, '_on_player_near_dialogue', [$Ship, true])
	$Ship/DialogueStarter.connect('body_exited', self, '_on_player_near_dialogue', [$Ship, false])

	$Dialogue/Wol.connect('finished', self, '_on_finished')

func _on_player_near_dialogue(_player, node, entered):
	if entered:
		current_dialogue = node.name
	else:
		current_dialogue = null

func _on_finished():
	$DialogueCooldown.start()

func _process(_delta):
	if Input.is_action_just_released('ui_accept') \
			and current_dialogue and not $Dialogue/Wol.running and $DialogueCooldown.time_left == 0:
		$Dialogue/Wol.starting_node = current_dialogue
		$Dialogue/Wol.path = 'res://ExampleDialogue/%s.yarn' % current_dialogue
		$Dialogue/Wol.start()
