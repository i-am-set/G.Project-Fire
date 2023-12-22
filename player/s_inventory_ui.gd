extends Control

@export var inventory_list: Node
@export var capacity_progress_bar: Node

func _ready():
	close()

func _process(delta):
	if Input.is_action_just_pressed("inventory"):
		if inventory_list.is_open:
			close()
		else:
			open()
	
	if Input.is_action_just_pressed("interact"):
		print("stick created")
		inventory_list._create_stick_on_floor()

func open():
	visible = true
	inventory_list.is_open = true
	inventory_list._refresh()

func close():
	visible = false
	inventory_list.is_open = false
	inventory_list.selected_inventory_item_id = ""
