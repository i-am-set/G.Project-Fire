extends CharacterBody3D

@export var player_model: Node3D
@export var inventory_list: ScrollContainer
@export var camera: Camera3D
@export var camera_pivot: Node3D
@export var subviewport_container: SubViewportContainer

var dropRadius: float = 1.0
var dropDistance: float  = 2.0
var rawPlayerInput: Vector2
var playerInput: Vector2
var moveDir: Vector2 = Vector2(-1, 0)
var forward: Vector2
var rawVelocity: Vector3

const ROTATESPEED: float = 1
const SPEED: float  =  7.0
const ACCEL: float  = 5

func get_input():
	var input: Vector2
	
	# Get the input based on "right", "left", "down", and "up"
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	rawPlayerInput = input.normalized()
	
	# Get the forward direction based on camera and player rotation
	forward = (Vector2(camera.global_transform.origin.x, camera.global_transform.origin.z) - Vector2(self.global_transform.origin.x, self.global_transform.origin.z)).normalized()
	
	# Rotate the input vector to be relative to the forward direction
	var rotated_input = Vector2(input.y, -input.x).rotated(forward.angle())
	
	# Update the input variable with the rotated input
	input.x = rotated_input.x
	input.y = rotated_input.y
	
	return input.normalized()

func _input(_event):
	if Input.is_action_just_released("zoom_in"):
		if camera.size > 40:
			camera.size -= 20
		if camera.size <= 40:
			camera.size = 40
		_zoom_pixelate()
	
	if Input.is_action_just_released("zoom_out"):
		if camera.size < 100:
			camera.size += 20
		if camera.size >= 100:
			camera.size = 100
		_zoom_pixelate()

func _process(delta):
	playerInput = get_input()
	if playerInput != Vector2.ZERO:
		moveDir = Vector2(playerInput.x, playerInput.y)
	
	_move(delta, playerInput)
	_rotate()

func _rotate():
	if Input.is_action_pressed("rotate_left"):
		camera_pivot.rotation_degrees.y -= ROTATESPEED
	if Input.is_action_pressed("rotate_right"):
		camera_pivot.rotation_degrees.y += ROTATESPEED

func _move(_delta: float, playerInput: Vector2):
	velocity = lerp(velocity,  Vector3(playerInput.x * SPEED, 0, playerInput.y * SPEED), _delta * ACCEL)
	
	var new_position = global_position - velocity
	
	if new_position != global_position:
		player_model.look_at(global_position - velocity, Vector3.UP)
	#_set_sprite(_delta)
	
	if(_check_if_busy() == true):
		return
	
	move_and_slide()

func _zoom_pixelate():
	if camera.size > 80:
		subviewport_container.stretch_shrink = 1
	elif camera.size > 60:
		subviewport_container.stretch_shrink = 1
	elif camera.size > 40:
		subviewport_container.stretch_shrink = 2
	else:
		subviewport_container.stretch_shrink = 3

#func _set_sprite(_delta: float):
	#rawVelocity = lerp(rawVelocity,  Vector3(rawPlayerInput.x * SPEED, 0, rawPlayerInput.y * SPEED), _delta * ACCEL)
	#
	#if rawVelocity.x + rawVelocity.y > 0:
		#if rawVelocity.x > rawVelocity.y:
			#sprite.frame = 0
		#elif rawVelocity.y > rawVelocity.x:
			#sprite.frame = 1
	#elif rawVelocity.x + rawVelocity.y < 0:
		#if rawVelocity.x < rawVelocity.y:
			#sprite.frame = 0
		#elif rawVelocity.y < rawVelocity.x:
			#sprite.frame = 2
	#
	#if rawVelocity.x > 0:
		#sprite.flip_h = true
	#elif rawVelocity.x < 0:
		#sprite.flip_h = false

func _check_if_busy() -> bool:
	if inventory_list.is_open:
		return true
	else:
		return false

func _get_random_position_around_player(circleRadius: float) -> Vector3:
	# Generate a random angle in radians
	var random_angle: float = randf_range(0, 2 * PI)
	
	# Generate a random distance within the circle's radius
	var random_distance: float = randf() * circleRadius
	
	# Calculate the new position using polar to Cartesian coordinates conversion
	var x: float = global_position.x + (moveDir.x*dropDistance) + random_distance * cos(random_angle)+1
	var y: float = 1
	var z: float = global_position.z + (moveDir.y*dropDistance) + random_distance * sin(random_angle)+1
	
	return Vector3(x, y, z)

func _show_ground_item(_ground_item_type: InventoryItem):
	inventory_list._show_ground_item(_ground_item_type)

func _unshow_ground_item(_ground_item_type: InventoryItem):
	inventory_list._unshow_ground_item(_ground_item_type)
