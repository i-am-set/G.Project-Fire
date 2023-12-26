extends Area3D

var item: InventoryItem
var item_id: String

func place_ground_item():
	$Sprite3D.texture = item.get_texture()
