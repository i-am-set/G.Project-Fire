extends Control

var is_open = false

func _ready():
	open()

func _process(delta):
	if Input.is_action_just_pressed("inventory"):
		if is_open:
			close()
		else:
			open()

func open():
	print("open")

func close():
	print("open")
