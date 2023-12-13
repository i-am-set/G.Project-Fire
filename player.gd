extends CharacterBody2D

@onready var sprite = $Sprite2D

const SPEED =  100.0
const ACCEL = 5

var input: Vector2

func get_input():
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	return input.normalized()

func _process(delta):
	var playerInput = get_input()
	
	velocity = lerp(velocity, playerInput * SPEED, delta * ACCEL)
	
	if velocity.x + velocity.y > 0:
		if velocity.x > velocity.y:
			sprite.frame = 0
		elif velocity.y > velocity.x:
			sprite.frame = 1
	elif velocity.x + velocity.y < 0:
		if velocity.x < velocity.y:
			sprite.frame = 0
		elif velocity.y < velocity.x:
			sprite.frame = 1
	
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false
	
	move_and_slide()
