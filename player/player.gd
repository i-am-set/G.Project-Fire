extends CharacterBody2D

@export var sprite: Sprite2D
@export var inventory_list: ScrollContainer

var dropRadius: float = 7.0
var dropDistance: float  = 12.0
var playerInput: Vector2
var moveDir: Vector2 = Vector2(-1, 0)

const SPEED =  45.0
const ACCEL = 10

var input: Vector2

func get_input():
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	return input.normalized()

func _process(delta):
	playerInput = get_input()
	if playerInput != Vector2.ZERO:
		moveDir = playerInput
	
	move(delta, playerInput)

func move(delta: float, playerInput: Vector2):
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
	
	if(_check_if_busy() == true):
		return
	
	move_and_slide()

func _check_if_busy() -> bool:
	if inventory_list.is_open:
		return true
	else:
		return false

func _get_random_position_around_player(circleRadius: float) -> Vector2:
	# Generate a random angle in radians
	var random_angle: float = randf_range(0, 2 * PI)
	
	# Generate a random distance within the circle's radius
	var random_distance: float = randf() * circleRadius
	
	# Calculate the new position using polar to Cartesian coordinates conversion
	var x: float = global_position.x + (moveDir.x*dropDistance) + random_distance * cos(random_angle)
	var y: float = global_position.y + (moveDir.y*dropDistance) + random_distance * sin(random_angle) - 3
	
	return Vector2(x, y)

func _show_ground_item(_ground_item_type: InventoryItem):
	inventory_list._show_ground_item(_ground_item_type)

func _unshow_ground_item(_ground_item_type: InventoryItem):
	inventory_list._unshow_ground_item(_ground_item_type)
