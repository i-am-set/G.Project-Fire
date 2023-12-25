extends ScrollContainer

signal inventory_item_activated(item)
signal refreshed

@export var inventory_path: NodePath :
	get:
		return inventory_path
	set(new_inv_path):
		inventory_path = new_inv_path
		var node: Node = get_node_or_null(inventory_path)

		if node == null:
			return

		if is_inside_tree():
			assert(node is Inventory)
			
		self.inventory = node
		update_configuration_warnings()

@export var default_item_icon: Texture2D

var inventory: Inventory = null :
	get:
		return inventory
	set(new_inventory):
		if new_inventory == inventory:
			return
	
		_disconnect_inventory_signals()
		inventory = new_inventory
		_connect_inventory_signals()

@onready var _player : Node = get_parent().get_parent().get_parent()
@onready var _entities_node : Node = get_tree().root.get_node("main").get_node("Entities")
@onready var possible_capacity_stylebox_normal = _possible_capacity_progress_bar.get_theme_stylebox("fill").duplicate()
@onready var possible_capacity_stylebox_heavy = _possible_capacity_progress_bar.get_theme_stylebox("fill").duplicate()

var _inventory_item_button_scene = preload("res://player/inventory_item.tscn")
var _inventory_item_button_group = preload("res://player/inventory_item_button_group.tres")
var _ground_item = preload("res://items/ground_item.tscn")

@export var _capacity_progress_bar: ProgressBar
@export var _possible_capacity_progress_bar: ProgressBar
@export var _vbox_container: VBoxContainer
@export var _pickup_area: Area2D
@export var _hand_slot: PanelContainer
@export var _context_menu: Panel

var is_refreshing : bool = false
var is_open : bool = false
var current_frame : int = 0
var selected_inventory_item_id: String = ""
var equipped_item: InventoryItem = null

func _get_configuration_warnings() -> PackedStringArray:
	if inventory_path.is_empty():
		return PackedStringArray([
				"This node is not linked to an inventory, so it can't display any content.\n" + \
				"Set the inventory_path property to point to an Inventory node."])
	return PackedStringArray()

func _ready():
	if has_node(inventory_path):
		self.inventory = get_node(inventory_path)
		
	_refresh()
	_set_possible_capacity_style_boxes()

#func _process(delta):
	#_process_every_60_frames()

func _process_every_60_frames():
	current_frame += 1
	
	# check if the specified number of frames has passed
	if current_frame >= 60:
		current_frame = 0
		
		# call functions here

func _connect_inventory_signals() -> void:
	if !inventory:
		return

	if !inventory.contents_changed.is_connected(_refresh):
		inventory.contents_changed.connect(_refresh)
	if !inventory.item_modified.is_connected(_on_item_modified):
		inventory.item_modified.connect(_on_item_modified)

func _disconnect_inventory_signals() -> void:
	if !inventory:
		return

	if inventory.contents_changed.is_connected(_refresh):
		inventory.contents_changed.disconnect(_refresh)
	if inventory.item_modified.is_connected(_on_item_modified):
		inventory.item_modified.disconnect(_on_item_modified)



func _refresh() -> void:
	if is_refreshing:
		return
	
	is_refreshing = true
	await get_tree().create_timer(0.01).timeout
	is_refreshing = false
	
	if is_inside_tree():
		_wipe_list()
		_populate_list()
		_clear_list()
		_update_capacity_progress_bar()
		refreshed.emit()

func _wipe_list() -> void:
	for child in _vbox_container.get_children():
		child._wipe()

func _clear_list() -> void:
	for child in _vbox_container.get_children():
		if child._is_wiped() == true:
			_vbox_container.remove_child(child)
			child.queue_free()

func _populate_list() -> void:
	if inventory == null:
		printerr("inventorys is null")
		return
	
	var inventoryItems: Array = []
	var groundItems: Array = []
	
	inventoryItems = inventory.get_items().duplicate()
	groundItems = _pickup_area._get_overlapping_items()
	
	# combine inventories with defining variables
	var combinedInventories: Array = []
	var sortedInventories: Array = []
	
	for item in inventoryItems:
		if item._is_equipped:
			sortedInventories.append({InventoryItem: item, Inventory: inventory})
		else:
			combinedInventories.append({InventoryItem: item, Inventory: inventory})
	for item in groundItems:
		combinedInventories.append({InventoryItem: item, Inventory: null})
	
	# sort the combined inventory array in alphbetical order
	combinedInventories.sort_custom(func(a,b): return a[InventoryItem].prototype_id < b[InventoryItem].prototype_id)
	
	# add all items in the combined inventories after the equipped items
	for entry in combinedInventories:
		sortedInventories.append({InventoryItem: entry[InventoryItem], Inventory: entry[Inventory]})
	
	# populate the inventory list via the combined and sorted inventories
	for entry in sortedInventories:
		var item = entry[InventoryItem]
		var _givenInventory = entry[Inventory]
		
		var texture = item.get_texture()
		if !texture:
			texture = default_item_icon
			
		
		if _vbox_container.get_child_count() <= 0:
			_create_item_button(_get_item_title(item), texture, item.prototype_id, item, _givenInventory)
		else:
			var tempItemIdList = []
			
			for current_item in _vbox_container.get_children():
				if current_item.item != equipped_item:
					tempItemIdList.append(current_item.item_id)
			
			if item.prototype_id in tempItemIdList && item != equipped_item:
				for current_item in _vbox_container.get_children():
					if current_item.item_id == item.prototype_id && current_item.item != equipped_item:
						if _givenInventory == inventory:
							current_item.main_item_amount += 1
						else:
							current_item.ground_item_amount += 1
			else:
				_set_up_new_button(item, texture, _givenInventory)

func _set_up_new_button(_item: InventoryItem, _texture: Texture2D, _givenInventory: Inventory):
	var hasRecyclableButtons: bool
	var recyclableButton: Node
	
	for child in _vbox_container.get_children():
		if child._is_wiped() == true:
			hasRecyclableButtons = true
			_recycle_item_button(child, _get_item_title(_item), _texture, _item.prototype_id, _item, _givenInventory)
			break
	
	if hasRecyclableButtons == false:
		_create_item_button(_get_item_title(_item), _texture, _item.prototype_id, _item, _givenInventory)

func _update_capacity_progress_bar():
	_capacity_progress_bar.max_value = inventory.capacity
	_capacity_progress_bar.value = inventory.occupied_space
	
	_possible_capacity_progress_bar.max_value = inventory.capacity
	
	if _get_selected_item_ground_count() > 0:
		if inventory.item_protoset.has_prototype(selected_inventory_item_id):
			var newWeight: int = inventory.occupied_space + inventory.item_protoset.get_item_property(selected_inventory_item_id, "weight")
			
			if newWeight > inventory.capacity:
				print("Item is too heavy.")
				_possible_capacity_progress_bar.add_theme_stylebox_override("fill", possible_capacity_stylebox_heavy)
				_possible_capacity_progress_bar.value = inventory.capacity
			else:
				_possible_capacity_progress_bar.add_theme_stylebox_override("fill", possible_capacity_stylebox_normal)
				_possible_capacity_progress_bar.value = newWeight
		else:
			_possible_capacity_progress_bar.value = 0
	else:
		_possible_capacity_progress_bar.value = 0

func _create_item_button(_item_title: String, _item_texture: Texture2D, _item_id: String, _item: InventoryItem, _given_inventory: Inventory):
	var _inventory_item_button_instance = _inventory_item_button_scene.instantiate()
	_inventory_item_button_instance.set_meta_data(_item_title, _item_texture, _item_id, _item, _item._is_equipped)
	_inventory_item_button_instance.button_group = _inventory_item_button_group
	
	if _given_inventory == inventory:
		_inventory_item_button_instance.main_item_amount += 1
	else:
		_inventory_item_button_instance.ground_item_amount += 1
	
	if selected_inventory_item_id == _item_id:
		_inventory_item_button_instance.button_pressed = true
	
	_vbox_container.add_child(_inventory_item_button_instance)

func _recycle_item_button(_recycled_button: Node, _item_title: String, _item_texture: Texture2D, _item_id: String, _item: InventoryItem, _given_inventory: Inventory):
	_recycled_button.set_meta_data(_item_title, _item_texture, _item_id, _item, _item._is_equipped)
	_recycled_button.button_group = _inventory_item_button_group
	
	if _given_inventory == inventory:
		_recycled_button.main_item_amount += 1
	else:
		_recycled_button.ground_item_amount += 1
	
	if selected_inventory_item_id == _item_id:
		_recycled_button.button_pressed = true

func _pick_up_item(_picked_up_item_id: String):
	var tempGroundItemInstanceArray = []
	var tempGroundItemArray = []
	
	tempGroundItemInstanceArray = _pickup_area.get_overlapping_areas().duplicate()
	tempGroundItemArray = _pickup_area._get_overlapping_items().duplicate()
	
	if !_picked_up_item_id in _pickup_area._get_overlapping_item_ids().duplicate():
		print("No item to pick up.")
		return
	
	# try to transfer the item from ground to main inventory
	for ground_item in tempGroundItemArray:
		if ground_item.prototype_id == _picked_up_item_id:
			if inventory.can_add_item(ground_item):
				inventory.add_item(ground_item)
			else:
				print("Can't add item.")
				return
			break
	
	# remove the ground item
	for ground_item_instance in tempGroundItemInstanceArray:
		if ground_item_instance.item_id == _picked_up_item_id:
			_entities_node.remove_child(ground_item_instance)
			ground_item_instance.queue_free()
			break
			
	_refresh()

func _drop_item(_dropped_item: InventoryItem):
	var tempItemList = []
	for item in inventory.get_items():
		tempItemList.append(item)
	if !_dropped_item in tempItemList:
		print("No item to drop.")
		return
	
	#remove the item from the inventory
	if _dropped_item in inventory.get_items():
		if(inventory._can_remove_item(_dropped_item)):
			var ground_item = _ground_item.instantiate()
			
			if _dropped_item._is_equipped:
				_unequip(_dropped_item)
			
			inventory.remove_item(_dropped_item)
			
			ground_item.global_position = _player._get_random_position_around_player(_player.dropRadius)
			ground_item.item = _dropped_item
			ground_item.item_id = _dropped_item.prototype_id
			ground_item.place_ground_item()
			
			_entities_node.add_child(ground_item)
	
	_refresh()

func _show_ground_item(_ground_item: InventoryItem):
	if(is_open):
		_refresh()

func _unshow_ground_item(_ground_item: InventoryItem):
	if(is_open):
		_refresh()

func _popup_context_menu(_button_instance: Node, _item: InventoryItem, _id: String, _ground_amount: int, _inventory_amount: int):
	var last_mouse_position = get_global_mouse_position()
	_context_menu._populate_context_menu(_item, _id, _can_equip(_id), _ground_amount, _inventory_amount)
	
	await get_tree().create_timer(0.01).timeout
	
	_context_menu._relocate_context_menu(last_mouse_position)

func _hide_context_menu():
	_context_menu._hide_context_menu()

func _equip(_item_to_equip: InventoryItem):
	if equipped_item != null:
		_unequip(equipped_item)
	
	for item in inventory.get_items():
		if item.prototype_id == _item_to_equip.prototype_id:
			item._is_equipped = true
			equipped_item = item
			break
	
	_hand_slot._equip_slot(_item_to_equip)
	
	_refresh()

func _unequip(_item_to_unequip: InventoryItem):
	for item in inventory.get_items():
		if item == _item_to_unequip:
			item._is_equipped = false
			equipped_item = null
			break
	
	_hand_slot._unequip_slot()
	
	_refresh()

func _can_equip(_id: String) -> bool:
	if inventory.item_protoset.get_item_property(_id, "equipable") == false:
		return false
	if !inventory.has_item_by_id(_id):
		return false
	return true

func _can_equip_currently_selected(_item: InventoryItem) -> bool:
	if selected_inventory_item_id != null:
		return inventory.item_protoset.get_item_property(selected_inventory_item_id, "equipable")
	else:
		return false

func _create_stick_on_floor():
	var item: InventoryItem = InventoryItem.new()
	item.protoset = inventory.item_protoset
	item.prototype_id = "wooden_stick"
	var ground_item = _ground_item.instantiate()
	
	ground_item.global_position = _player._get_random_position_around_player(_player.dropRadius)
	if inventory.get_items().size() >= 0:
		ground_item.item = item
		ground_item.item_id = "wooden_stick"
		ground_item.place_ground_item()
	
	_entities_node.add_child(ground_item)

func _get_selected_item_inventory_count() -> int:
	for current_item in _vbox_container.get_children():
		if selected_inventory_item_id == current_item.item_id:
			return current_item.main_item_amount
	return 0

func _get_selected_item_ground_count() -> int:
	for current_item in _vbox_container.get_children():
		if selected_inventory_item_id == current_item.item_id:
			return current_item.ground_item_amount
	return 0

func _get_item_title(item: InventoryItem) -> String:
	if item == null:
		return ""

	var title = item.get_title()
	var stack_size: int = InventoryStacked.get_item_stack_size(item)
	if stack_size > 1:
		title = "%s (x%d)" % [title, stack_size]

	return title

func _on_item_modified(_item: InventoryItem) -> void:
	_refresh()

func _set_possible_capacity_style_boxes():
	possible_capacity_stylebox_normal.bg_color = Color8(144, 181, 255)
	possible_capacity_stylebox_heavy.bg_color = Color8(255, 49, 64)
