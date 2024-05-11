extends Resource
class_name NpcShop

@export var shopItemSlots: Array[ShopInventorySlot] = []

func _init(
	i_shopItemSlots: Array[ShopInventorySlot] = []
):
	shopItemSlots = i_shopItemSlots
