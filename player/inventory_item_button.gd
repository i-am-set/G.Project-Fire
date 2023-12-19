extends Button

@export var ground_amount_label: Label
@export var inventory_amount_label: Label

# Use a unique name for your custom signal
signal inventory_item_button_pressed(item_count)

var item_amount: int = 1
var item_position: int
var item_type: InventoryItem

func _process(delta):
	if item_amount > 0:
		inventory_amount_label.text = str(item_amount)
		inventory_amount_label.visible = true

func set_meta_data(_item_title: String, _item_texture: Texture2D, _item_position: int, _item_type: InventoryItem):
	text = _item_title
	icon = _item_texture
	item_position = _item_position
	item_type = _item_type

func _on_pressed():
	# Emit the custom signal with the custom data when the button is pressed
	emit_signal("custom_button_pressed", item_type)
