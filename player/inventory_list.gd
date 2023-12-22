extends ScrollContainer

signal inventory_item_activated(item)

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

@export var _capacity_progress_bar : ProgressBar
@export var _possible_capacity_progress_bar : ProgressBar
@export var _vbox_container: VBoxContainer
@export var _pickup_area : Area2D

var is_open : bool = false
var current_frame : int = 0
var selected_inventory_item_id: String = ""

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
	await get_tree().create_timer(0.01).timeout
	
	if is_inside_tree():
		_clear_list()
		_populate_list()
		_update_capacity_progress_bar()

func _clear_list() -> void:
	for child in _vbox_container.get_children():
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
	
	for item in inventoryItems:
		combinedInventories.append({InventoryItem: item, Inventory: inventory})
	for item in groundItems:
		combinedInventories.append({InventoryItem: item, Inventory: null})
	
	# sort the combined inventory array in alphbetical order
	combinedInventories.sort_custom(func(a,b): return a[InventoryItem].prototype_id < b[InventoryItem].prototype_id)
	
	# populate the inventory list via the combined and sorted inventories
	for entry in combinedInventories:
		var item = entry[InventoryItem]
		var _givenInventory = entry[Inventory]
		
		var texture = item.get_texture()
		if !texture:
			texture = default_item_icon
			
		if _vbox_container.get_child_count() <= 0:
			_create_item_button(_get_item_title(item), texture, item.prototype_id, item)
			if _givenInventory == inventory:
				_vbox_container.get_child(0).main_item_amount += 1
			else:
				_vbox_container.get_child(0).ground_item_amount += 1
		else:
			var tempItemList = []
			
			for current_item in _vbox_container.get_children():
				tempItemList.append(current_item.item_id)
			
			if item.prototype_id in tempItemList:
				for current_item in _vbox_container.get_children():
					if current_item.item_id == item.prototype_id:
						if _givenInventory == inventory:
							current_item.main_item_amount += 1
						else:
							current_item.ground_item_amount += 1
			else:
				_create_item_button(_get_item_title(item), texture, item.prototype_id, item)
				for current_item in _vbox_container.get_children():
					if item.prototype_id == current_item.item_id:
						if _givenInventory == inventory:
							current_item.main_item_amount += 1
						else:
							current_item.ground_item_amount += 1

func _update_capacity_progress_bar():
	_capacity_progress_bar.max_value = inventory.capacity
	_capacity_progress_bar.value = inventory.occupied_space
	
	_possible_capacity_progress_bar.max_value = inventory.capacity
	
	if _get_selected_item_ground_count() > 0:
		if inventory.item_protoset.has_prototype(selected_inventory_item_id):
			var newWeight: int = inventory.occupied_space + inventory.item_protoset.get_item_property(selected_inventory_item_id, "weight")
			
			if newWeight > inventory.capacity:
				print("too heavy")
				_possible_capacity_progress_bar.add_theme_stylebox_override("fill", possible_capacity_stylebox_heavy)
				_possible_capacity_progress_bar.value = inventory.capacity
			else:
				_possible_capacity_progress_bar.add_theme_stylebox_override("fill", possible_capacity_stylebox_normal)
				_possible_capacity_progress_bar.value = newWeight
		else:
			_possible_capacity_progress_bar.value = 0
	else:
		_possible_capacity_progress_bar.value = 0

func _sort_name(a, b) -> bool:
	return a.Name < b.Name

func _create_item_button(_item_title: String, _item_texture: Texture2D, _item_id: String, _item: InventoryItem):
	var _inventory_item_button_instance = _inventory_item_button_scene.instantiate()
	_inventory_item_button_instance.set_meta_data(_item_title, _item_texture, _item_id, _item)
	_inventory_item_button_instance.button_group = _inventory_item_button_group
	
	if selected_inventory_item_id == _item_id:
		_inventory_item_button_instance.button_pressed = true
	
	_vbox_container.add_child(_inventory_item_button_instance)

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
				print("Item is too heavy.")
				return
			break
	
	# remove the ground item
	for ground_item_instance in tempGroundItemInstanceArray:
		if ground_item_instance.item_id == _picked_up_item_id:
			_entities_node.remove_child(ground_item_instance)
			ground_item_instance.queue_free()
			break
			
	_refresh()

func _drop_item(_dropped_item_id: String):
	var tempItemList = []
	for item in inventory.get_items():
		tempItemList.append(item.prototype_id)
	if !_dropped_item_id in tempItemList:
		print("No item to drop.")
		return
	
	var ground_item = _ground_item.instantiate()
	
	#remove the item from the inventory
	for item in inventory.get_items():
		if item.prototype_id == _dropped_item_id:
			if(inventory._can_remove_item(item)):
				inventory.remove_item(item)
			
			ground_item.global_position = _player._get_random_position_around_player(_player.dropRadius)
			if inventory.get_items().size() >= 0:
				ground_item.item = item
				ground_item.item_id = item.prototype_id
				ground_item.place_ground_item()
			break
	
	_entities_node.add_child(ground_item)
	
	_refresh()

func _show_ground_item(_ground_item: InventoryItem):
	_refresh()

func _unshow_ground_item(_ground_item: InventoryItem):
	_refresh()

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
	possible_capacity_stylebox_normal.bg_color = Color8(144, 181, 198)
	possible_capacity_stylebox_heavy.bg_color = Color8(97, 49, 64)
