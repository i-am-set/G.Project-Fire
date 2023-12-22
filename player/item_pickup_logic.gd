extends Area2D

@onready var parent_node: Node = get_parent()

func _on_area_entered(area):
	if area.item != null:
		parent_node._show_ground_item(area.item)

func _on_area_exited(area):
	if area.item != null:
		parent_node._unshow_ground_item(area.item)

func _get_overlapping_items() -> Array:
	var tempItemList = []
	for ground_item in get_overlapping_areas():
		tempItemList.append(ground_item.item)
	return tempItemList

func _get_overlapping_item_ids() -> Array:
	var tempItemList = []
	for ground_item in get_overlapping_areas():
		tempItemList.append(ground_item.item_id)
	return tempItemList
