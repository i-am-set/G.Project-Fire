extends Panel

@export var _inventory_list: ScrollContainer
@export var _vbox_container: VBoxContainer

@onready var _all_context_buttons: Array = _vbox_container.get_children()
@onready var _button_equip: Button = _vbox_container.get_child(0)
@onready var _button_pick_up: Button = _vbox_container.get_child(1)
@onready var _button_drop: Button = _vbox_container.get_child(2)

var _current_item: InventoryItem
var _current_item_id: String

func _populate_context_menu(_item: InventoryItem, _id: String, _can_equip: bool, _ground_amount: int, _inventory_amount: int) -> void:
	_clear_context_menu()
	
	_current_item = _item
	_current_item_id = _id
	
	if _can_equip:
		_button_equip.visible = true
	if _ground_amount > 0:
		_button_pick_up.visible = true
	if _inventory_amount > 0:
		_button_drop.visible = true

func _clear_context_menu() -> void:
	self.size = Vector2(0, 0)
	
	for context_button in _all_context_buttons:
		context_button.visible = false

func _relocate_context_menu(_last_mouse_position: Vector2):
	self.visible = true
	self.size = _vbox_container.size
	self.position = _last_mouse_position

func _hide_context_menu():
	self.visible = false
	_current_item = null
	_current_item_id = ""

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = get_global_mouse_position()
			var is_mouse_inside = get_rect().has_point(mouse_position)
			
			if !is_mouse_inside:
				_hide_context_menu()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_hide_context_menu()

func _on_equip_button_pressed():
	_inventory_list._equip(_current_item)
	_hide_context_menu()

func _on_pick_up_button_pressed():
	if _current_item_id == "":
		printerr("No item selected in context menu.")
		return
	_inventory_list._pick_up_item(_current_item_id)
	_hide_context_menu()

func _on_drop_button_pressed():
	if _current_item_id == "":
		printerr("No item selected in context menu.")
		return
	_inventory_list._drop_item(_current_item)
	_hide_context_menu()
