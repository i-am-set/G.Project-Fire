extends PanelContainer

@export var item_slot_path: NodePath :
	get:
		return item_slot_path
	set(new_item_slot_path):
		item_slot_path = new_item_slot_path
		var node: Node = get_node_or_null(item_slot_path)
		
		if node == null:
			return
		
		if is_inside_tree():
			assert(node is ItemSlot)
			
		self.item_slot = node
		update_configuration_warnings()

@export var default_item_icon: Texture2D :
	get:
		return default_item_icon
	set(new_default_item_icon):
		default_item_icon = new_default_item_icon
		_refresh()

var item_slot: ItemSlot :
	get:
		return item_slot
	set(new_item_slot):
		if new_item_slot == item_slot:
			return
		
		_disconnect_item_slot_signals()
		item_slot = new_item_slot
		_connect_item_slot_signals()
		
		_refresh()


@onready var _texture_rect: TextureRect = get_child(0)

var _gloot: Node = null


func _get_configuration_warnings() -> PackedStringArray:
	if item_slot_path.is_empty():
		return PackedStringArray([
			"This node is not linked to an item slot, so it can't display any content.\n" + \
			"Set the item_slot_path property to point to an ItemSlot node."])
	return PackedStringArray()


func _connect_item_slot_signals() -> void:
	if !item_slot:
		return

	if !item_slot.item_set.is_connected(_on_item_set):
		item_slot.item_set.connect(_on_item_set)
	if !item_slot.item_cleared.is_connected(_refresh):
		item_slot.item_cleared.connect(_refresh)
	if !item_slot.inventory_changed.is_connected(_on_inventory_changed):
		item_slot.inventory_changed.connect(_on_inventory_changed)


func _disconnect_item_slot_signals() -> void:
	if !item_slot:
		return

	if item_slot.item_set.is_connected(_on_item_set):
		item_slot.item_set.disconnect(_on_item_set)
	if item_slot.item_cleared.is_connected(_refresh):
		item_slot.item_cleared.disconnect(_refresh)
	if item_slot.inventory_changed.is_connected(_on_inventory_changed):
		item_slot.inventory_changed.disconnect(_on_inventory_changed)

func _on_item_set(_item: InventoryItem) -> void:
	_refresh()

func _on_inventory_changed(_inventory: Inventory) -> void:
	_refresh()


func _ready():
	_gloot = _get_gloot()
	
	var node: Node = get_node_or_null(item_slot_path)
	if is_inside_tree() && node:
		assert(node is ItemSlot)
	self.item_slot = node

	_refresh()


func _get_gloot() -> Node:
	# This is a "temporary" hack until a better solution is found!
	# This is a tool script that is also executed inside the editor, where the "GLoot" singleton is
	# not visible - leading to errors inside the editor.
	# To work around that, we obtain the singleton by name.
	return get_tree().root.get_node_or_null("GLoot")


func _get_singleton() -> Node:
	return null

func _equip_slot(_item: InventoryItem):
	item_slot.item = _item

func _unequip_slot():
	item_slot.item = null

func _refresh() -> void:
	_clear()
	
	if item_slot == null:
		return
	
	if item_slot.item == null:
		return

	var item = item_slot.item
	if _texture_rect:
		_texture_rect.texture = item.get_texture()


func _clear() -> void:
	if _texture_rect:
		_texture_rect.texture = null

