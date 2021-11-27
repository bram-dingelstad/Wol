extends KinematicBody2D

var velocity = Vector2.ZERO
var time = .0

func _physics_process(_delta):
	var gravity = Vector2.DOWN * 9.81

	velocity += gravity

	move_and_slide(velocity, Vector2.UP)

func _process(delta):
	var direction = Input.get_vector('ui_left', 'ui_right', 'ui_select', 'ui_select')

	# Jump
	if Input.is_action_just_released('ui_select') and is_on_floor():
		velocity += Vector2.UP * 9.81 * 50

	velocity.x = direction.x * 200

	if direction.x != 0:
		time += delta

		$LeftFoot.visible = fmod(time * 4, 2) > 1
		$RightFoot.visible = not $LeftFoot.visible
	else:
		$LeftFoot.visible = true
		$RightFoot.visible = true

	$Visuals.scale.x = -1 if velocity.x < 0 else 1

