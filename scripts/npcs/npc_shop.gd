extends Resource
class_name NpcShop

@export var shopItemSlots: Array[ShopInventorySlot] = []

func _init(
	i_shopItemSlots: Array[ShopInventorySlot] = []
):
	shopItemSlots = i_shopItemSlots

func has_item_in_shop(item: Item) -> bool:
	for slot in shopItemSlots:
		if slot.item.itemName == item.itemName:
			return true
	return false
