extends Node3D

var frame_counter : int = 0
var total_ticks_in_a_day = 1440
var total_ticks_multiplier : float
var current_hour
var current_minute
var is_day : bool
var am_pm : String
var target_light_energy : float
var lerp_factor : float
var time_of_day : int :
	get: return time_of_day
	set(value):
		time_of_day = value % total_ticks_in_a_day
		current_hour = time_of_day / 60
		am_pm = "AM"
		if current_hour >= 12:
			am_pm = "PM"
			if current_hour > 12:
				current_hour -= 12
		current_minute = time_of_day % 60
		print("Time set to " + str(current_hour).pad_zeros(2) + ":" + str(current_minute).pad_zeros(2) + " " + am_pm)

# Exposed variable for the sunlight node
@export var sun_light : DirectionalLight3D
@export var day_cycle_speed = 0.15

func _ready():
	total_ticks_multiplier = 360/total_ticks_in_a_day
	#update_sun_position()

# Called every frame. Put your game logic here.
func _physics_process(delta):
	frame_counter += 1

	sun_light.rotation.x += deg_to_rad(day_cycle_speed * delta)
	
	# Set target light energy based on is_day
	if is_day:
		target_light_energy = 1.0
	else:
		target_light_energy = 0.0
	
	# Smoothly interpolate light energy
	sun_light.light_energy = lerp(sun_light.light_energy, target_light_energy, 0.01)
	
	# Check if it's daytime
	is_day = (time_of_day >= 360 && time_of_day <= 1080)
	
	time_of_day = (sun_light.rotation_degrees.x+270) / 0.25
	print(time_of_day)
