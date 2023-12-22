extends Node2D

var item_type: InventoryItem

func place_ground_item():
	$Sprite2D.texture = item_type.get_texture()

func _on_area_2d_body_entered(body):
	if body.has_method("show_ground_item"):
		body.show_ground_item(item_type)

func _on_area_2d_body_exited(body):
	if body.has_method("unshow_ground_item"):
		body.unshow_ground_item(item_type)

func _process(delta):
	for area in $Area2D.get_overlapping_bodies():
		print(area)
