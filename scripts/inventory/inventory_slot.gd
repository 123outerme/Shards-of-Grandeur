extends Resource
class_name InventorySlot

@export var item: Item = null
@export var count = 1

func _init(i: Item = null, i_count = 1):
	item = i
	count = i_count
