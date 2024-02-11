extends GridMap

# Initialize noise generators for different map features
# Values between -1 and 1
var moisture = FastNoiseLite.new()
var temperature = FastNoiseLite.new()
var altitude = FastNoiseLite.new()

# Dimensions of each generated chunk
var width = 128
var length = 128

# Reference to the player character
@export var player: Node
var last_player_cell_pos : Vector3i

# List to keep track of loaded chunks
var loaded_chunks = []

func _ready():
	# Set random seeds for noise variation
	moisture.seed = randi()
	temperature.seed = randi()
	altitude.seed = randi()

	# Adjust this value to change the 'smoothness' of the map; lower values mean more smooth noise
	altitude.frequency = 0.01
	
	# generate the first chunk
	var player_cell_pos = local_to_map(player.position)
	generate_chunk(player_cell_pos)
	last_player_cell_pos = player_cell_pos

func _process(delta):
	# Convert the player's position to cell coordinates
	var player_cell_pos = local_to_map(player.position)
	
	if last_player_cell_pos == null:
		return
	
	if player_cell_pos != last_player_cell_pos:
		# Generate the chunk at the player's position
		generate_chunk(player_cell_pos)
		# Unload chunks that are too far away.
		unload_distant_chunks(player_cell_pos)


func generate_chunk(pos):
	var posx_calc = pos.x - (width/2)
	var posz_calc = pos.z - (length/2)
	for x in range(width):
		for z in range(length):
			var posx_calc_step2 = posx_calc + x
			var posz_calc_step2 = posz_calc + z
			# Generate noise values for moisture, temperature, and altitude
			var moist = moisture.get_noise_2d(posx_calc_step2, posz_calc_step2) * 10  # Values between -10 and 10
			var temp = temperature.get_noise_2d(posx_calc_step2, posz_calc_step2) * 10
			var alt = altitude.get_noise_2d(posx_calc_step2, posz_calc_step2) * 10

			# Set the cell based on altitude; adjust for different tile types
			# Need to evenly distribute -10 -> 10 to 0 -> 4....  This can be done by first adding 10
			# Gets values from 0 -> 20... Then we will multiply by 3/20 in order to remap it to 0 -> 3
			# vvv
			
			if alt < 0:  # Arbitrary sea level value (choosing 0 will mean roughly 1/2 the world is ocean)
				set_cell_item(Vector3i(posx_calc_step2, 0, posz_calc_step2), 0)
			else:  # You can add other logic like making beaches by setting item to whatever beach atlas item is when the alt is between 0 and 0.5 or something
				set_cell_item(Vector3i(posx_calc_step2, 0, posz_calc_step2), 1)

			if Vector3i(pos.x, 0, pos.z) not in loaded_chunks:
				loaded_chunks.append(Vector3i(pos.x, 0, pos.z))
				
			#await get_tree().process_frame

# Function to unload chunks that are too far away
func unload_distant_chunks(player_pos):
	# Set the distance threshold to at least 2 times the width to limit visual glitches
	# Higher values unload chunks further away
	var unload_distance_threshold = (width * 2) + 1

	for chunk in loaded_chunks:
		var distance_to_player = get_dist(chunk, player_pos)

		if distance_to_player > unload_distance_threshold:
			clear_chunk(chunk)
			loaded_chunks.erase(chunk)

# Function to clear a chunk
func clear_chunk(pos):
	for x in range(width):
		for z in range(length):
			set_cell_item(Vector3i(pos.x - (width/2) + x, 0, pos.z - (length/2) + z), -1)

# Function to calculate distance between two points
func get_dist(p1, p2):
	var resultant = p1 - p2
	return sqrt(resultant.x ** 2 + resultant.y ** 2)
