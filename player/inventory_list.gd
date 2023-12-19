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

var _inventory_item_button_scene = preload("res://player/inventory_item.tscn")
var _inventory_item_button_group = preload("res://player/inventory_item_button_group.tres")
@export var _vbox_container: VBoxContainer

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
	if is_inside_tree():
		_clear_list()
		_populate_list()

func _clear_list() -> void:
	for child in _vbox_container.get_children():
		child.queue_free()

func _populate_list() -> void:
	if inventory == null:
		return

	for item in inventory.get_items():
		var texture := item.get_texture()
		if !texture:
			texture = default_item_icon
		if _vbox_container.get_child_count() <= 0:
			add_item(_get_item_title(item), texture, _vbox_container.get_child_count(), item)
		else:
			for current_item in _vbox_container.get_children():
				if item.get_title() == current_item.text:
					current_item.item_amount += 1
					break
				else:
					add_item(_get_item_title(item), texture, _vbox_container.get_child_count(), item)
					break

func add_item(_item_title: String, _item_texture: Texture2D, _item_count: int, _item: InventoryItem):
	var _inventory_item_button_instance = _inventory_item_button_scene.instantiate()
	_inventory_item_button_instance.set_meta_data(_item_title, _item_texture, _item_count, _item)
	_inventory_item_button_instance.button_group = _inventory_item_button_group
	
	_vbox_container.add_child(_inventory_item_button_instance)

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
