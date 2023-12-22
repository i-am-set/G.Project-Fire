extends Button

@export var ground_amount_label: Label
@export var main_amount_label: Label

@export var left_button: Button
@export var right_button: Button

@onready var inventoryList: Node = get_parent().get_parent()

# Use a unique name for your custom signal
signal inventory_item_button_pressed(item_type)

var main_item_amount: int
var ground_item_amount: int

var item_id: String
var item: InventoryItem

func _process(delta):
	if main_item_amount > 0:
		main_amount_label.text = str(main_item_amount)
		main_amount_label.visible = true
		left_button.visible = true
	else:
		main_amount_label.visible = false
		left_button.visible = false
	
	if ground_item_amount > 0:
		ground_amount_label.text = str(ground_item_amount)
		ground_amount_label.visible = true
		right_button.visible = true
	else:
		ground_amount_label.visible = false
		right_button.visible = false

func set_meta_data(_item_title: String, _item_texture: Texture2D, _item_id: String, _item: InventoryItem):
	$Title.text = _item_title
	$Texture.texture = _item_texture
	item_id = _item_id
	item = _item

func _on_pressed():
	# Emit the custom signal with the custom data when the button is pressed
	emit_signal("inventory_item_button_pressed", item)
	if inventoryList != null:
			inventoryList._update_capacity_progress_bar()

func _on_left_button_pressed():
	inventoryList._drop_item(item_id)

func _on_right_button_pressed():
	inventoryList._pick_up_item(item_id)

func _on_toggled(toggled_on):
	if toggled_on:
		if inventoryList != null:
			inventoryList.selected_inventory_item_id = item_id
		left_button.disabled = false
		right_button.disabled = false
	else:
		left_button.disabled = true
		right_button.disabled = true
