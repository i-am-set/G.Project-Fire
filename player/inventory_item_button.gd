extends Button

@export var ground_amount_label: Label
@export var main_amount_label: Label
@export var status_label: Label

@export var left_button: Button
@export var right_button: Button

@onready var inventoryList: Node = get_parent().get_parent()

var wiped: bool = false

var main_item_amount: int
var ground_item_amount: int
var is_equipped: bool

var item_id: String
var item: InventoryItem


func _connect_item_slot_signals() -> void:
	if !inventoryList:
		return

	if !inventoryList.refreshed.is_connected(_refresh):
		inventoryList.refreshed.connect(_refresh)

func _disconnect_item_slot_signals() -> void:
	if !inventoryList:
		return

	if inventoryList.refreshed.is_connected(_refresh):
		inventoryList.refreshed.disconnect(_refresh)


func _ready():
	_disconnect_item_slot_signals()
	_connect_item_slot_signals()

func _refresh():
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
	
	if is_equipped:
		status_label.visible = true
		main_amount_label.visible = false
	else:
		status_label.visible = false

func set_meta_data(_item_title: String, _item_texture: Texture2D, _item_id: String, _item: InventoryItem, _is_equipped: bool):
	$Title.text = _item_title
	$Texture.texture = _item_texture
	item_id = _item_id
	item = _item
	is_equipped = _is_equipped
	wiped = false

func _on_pressed():
	if inventoryList != null:
			inventoryList._update_capacity_progress_bar()

func _on_left_button_pressed():
	inventoryList._drop_item(item)

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

func _wipe():
	main_item_amount = 0
	ground_item_amount = 0
	item_id = "null"
	item = null
	wiped = true

func _is_wiped() -> bool:
	return wiped

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				inventoryList._popup_context_menu(self, item, item_id, ground_item_amount, main_item_amount)
