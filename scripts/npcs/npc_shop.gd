extends Resource
class_name NpcShop

## if not empty, will initialize a shared NPC inventory under this ID
@export var id: String = ''

## inventory of the shop
@export var shopItemSlots: Array[ShopInventorySlot] = []

func _init(
	i_id: String = '',
	i_shopItemSlots: Array[ShopInventorySlot] = []
):
	id = i_id
	shopItemSlots = i_shopItemSlots

func has_item_in_shop(item: Item) -> bool:
	for slot in shopItemSlots:
		if slot.item.itemName == item.itemName:
			return true
	return false
