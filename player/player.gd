extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var inventoryList = $CanvasLayer/UserInterface/InventoryList

var dropRadius: float = 10.0

const SPEED =  45.0
const ACCEL = 10

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
			sprite.frame = 2
	
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false
	
	move_and_slide()

func get_random_position_around_player(circleRadius: float) -> Vector2:
	# Generate a random angle in radians
	var random_angle: float = randf_range(0, 2 * PI)
	
	# Generate a random distance within the circle's radius
	var random_distance: float = randf() * circleRadius
	
	# Calculate the new position using polar to Cartesian coordinates conversion
	var x: float = global_position.x + random_distance * cos(random_angle)
	var y: float = global_position.y + random_distance * sin(random_angle)
	
	return Vector2(x, y)

func show_ground_item(_ground_item_type: InventoryItem):
	inventoryList.show_ground_item(_ground_item_type)

func unshow_ground_item(_ground_item_type: InventoryItem):
	inventoryList.unshow_ground_item(_ground_item_type)
