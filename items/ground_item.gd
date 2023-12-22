extends Area2D

var item: InventoryItem
var item_id: String

func place_ground_item():
	$Sprite2D.texture = item.get_texture()
