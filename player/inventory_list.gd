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

@export var ground_inventory_path: NodePath :
	get:
		return ground_inventory_path
	set(new_inv_path):
		ground_inventory_path = new_inv_path
		var node: Node = get_node_or_null(ground_inventory_path)

		if node == null:
			return

		if is_inside_tree():
			assert(node is Inventory)
			
		self.ground_inventory = node
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

var ground_inventory: Inventory = null :
	get:
		return ground_inventory
	set(new_inventory):
		if new_inventory == ground_inventory:
			return
	
		_disconnect_inventory_signals()
		ground_inventory = new_inventory
		_connect_inventory_signals()

@onready var _player : Node = get_parent().get_parent().get_parent()
var _inventory_item_button_scene = preload("res://player/inventory_item.tscn")
var _inventory_item_button_group = preload("res://player/inventory_item_button_group.tres")
var _ground_item = preload("res://items/ground_item.tscn")
@export var _vbox_container: VBoxContainer

func _get_configuration_warnings() -> PackedStringArray:
	if inventory_path.is_empty():
		return PackedStringArray([
				"This node is not linked to an inventory, so it can't display any content.\n" + \
				"Set the inventory_path property to point to an Inventory node."])
	return PackedStringArray()
	
	if ground_inventory_path.is_empty():
		return PackedStringArray([
				"This node is not linked to an inventory, so it can't display any content.\n" + \
				"Set the inventory_path property to point to an Inventory node."])
	return PackedStringArray()

func _ready():
	if has_node(inventory_path):
		self.inventory = get_node(inventory_path)
	if has_node(ground_inventory_path):
		self.ground_inventory = get_node(ground_inventory_path)
		
	_refresh()

func _connect_inventory_signals() -> void:
	if !inventory:
		return

	if !inventory.contents_changed.is_connected(_refresh):
		inventory.contents_changed.connect(_refresh)
	if !inventory.item_modified.is_connected(_on_item_modified):
		inventory.item_modified.connect(_on_item_modified)
	
	if !ground_inventory:
		return

	if !ground_inventory.contents_changed.is_connected(_refresh):
		ground_inventory.contents_changed.connect(_refresh)
	if !ground_inventory.item_modified.is_connected(_on_item_modified):
		ground_inventory.item_modified.connect(_on_item_modified)

func _disconnect_inventory_signals() -> void:
	if !inventory:
		return

	if inventory.contents_changed.is_connected(_refresh):
		inventory.contents_changed.disconnect(_refresh)
	if inventory.item_modified.is_connected(_on_item_modified):
		inventory.item_modified.disconnect(_on_item_modified)
	
	if !ground_inventory:
		return

	if ground_inventory.contents_changed.is_connected(_refresh):
		ground_inventory.contents_changed.disconnect(_refresh)
	if ground_inventory.item_modified.is_connected(_on_item_modified):
		ground_inventory.item_modified.disconnect(_on_item_modified)


func _refresh() -> void:
	if is_inside_tree():
		_clear_list()
		_populate_list()

func _clear_list() -> void:
	for child in _vbox_container.get_children():
		_vbox_container.remove_child(child)
		child.queue_free()

func _populate_list() -> void:
	if inventory == null:
		printerr("inventory is null")
		return
		
	# populate main inventory
	for item in inventory.get_items():
		var texture := item.get_texture()
		if !texture:
			texture = default_item_icon
			
		if _vbox_container.get_child_count() <= 0:
			create_item_button(_get_item_title(item), texture, item.prototype_id, item)
			_vbox_container.get_child(0).main_item_amount += 1
		else:
			var tempItemList = []
			
			for current_item in _vbox_container.get_children():
				tempItemList.append(current_item.item_id)
			
			if item.prototype_id in tempItemList:
				for current_item in _vbox_container.get_children():
					if current_item.item_id == item.prototype_id:
						current_item.main_item_amount += 1
			else:
				create_item_button(_get_item_title(item), texture, item.prototype_id, item)
				for current_item in _vbox_container.get_children():
					if item.prototype_id == current_item.item_id:
						current_item.main_item_amount += 1
		
	# populate ground inventory
	for item in ground_inventory.get_items():
		var texture := item.get_texture()
		if !texture:
			texture = default_item_icon
			
		if _vbox_container.get_child_count() <= 0:
			create_item_button(_get_item_title(item), texture, item.prototype_id, item)
			_vbox_container.get_child(0).ground_item_amount += 1
		else:
			var tempItemList = []
			
			for current_item in _vbox_container.get_children():
				tempItemList.append(current_item.item_id)
			
			if item.prototype_id in tempItemList:
				for current_item in _vbox_container.get_children():
					if current_item.item_id == item.prototype_id:
						current_item.ground_item_amount += 1
			else:
				create_item_button(_get_item_title(item), texture, item.prototype_id, item)
				for current_item in _vbox_container.get_children():
					if item.prototype_id == current_item.item_id:
						current_item.ground_item_amount += 1

func create_item_button(_item_title: String, _item_texture: Texture2D, _item_id: String, _item: InventoryItem):
	var _inventory_item_button_instance = _inventory_item_button_scene.instantiate()
	_inventory_item_button_instance.set_meta_data(_item_title, _item_texture, _item_id, _item)
	_inventory_item_button_instance.button_group = _inventory_item_button_group
	
	_vbox_container.add_child(_inventory_item_button_instance)

func drop_item(_dropped_item_id: String):
	var tempItemList = []
	for item in inventory.get_items():
		tempItemList.append(item.prototype_id)
	if !_dropped_item_id in tempItemList:
		return
	
	var child: InventoryItem
	var ground_item = _ground_item.instantiate()
	
	#remove the item from the inventory
	for i in range(inventory.get_items().size() - 1, -1, -1):
		child = inventory.get_items()[i]
		if child.prototype_id == _dropped_item_id:
			if(inventory._can_remove_item(child)):
				inventory.remove_item(child)
			break
	
	ground_item.global_position = _player.get_random_position_around_player(_player.dropRadius)
	if inventory.get_items().size() >= 0:
		ground_item.item_type = child
		ground_item.place_ground_item()
	get_tree().root.add_child(ground_item)

func show_ground_item(_ground_item: InventoryItem):
	ground_inventory.add_item(_ground_item)

func unshow_ground_item(_ground_item: InventoryItem):
	var child: InventoryItem
	
	for i in range(ground_inventory.get_items().size() - 1, -1, -1):
		child = ground_inventory.get_items()[i]
		if child.prototype_id == _ground_item.prototype_id:
			if(ground_inventory._can_remove_item(child)):
				ground_inventory.remove_item(child)
			break

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

func _on_inventory_item_inventory_item_button_pressed(button_data):
	print(button_data)
