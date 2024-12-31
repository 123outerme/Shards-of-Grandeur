extends PuzzleMechanic
class_name ItemsPuzzleMechanic

@export var item: Item = null
@export var requiredCount: int = 1
@export var consumeItem: bool = true

func _init(
	i_item: Item = null,
	i_requiredCount: int = 1,
	i_consumeItem: bool = true,
):
	item = i_item
	requiredCount = i_requiredCount
	consumeItem = i_consumeItem

func can_solve() -> bool:
	var inventorySlot: InventorySlot = PlayerResources.inventory.get_slot_for_item(item)
	return inventorySlot != null and inventorySlot.count >= requiredCount

func solve() -> bool:
	var inventorySlot: InventorySlot = PlayerResources.inventory.get_slot_for_item(item)
	if inventorySlot != null and inventorySlot.count >= requiredCount:
		if consumeItem:
			PlayerResources.inventory.trash_item(inventorySlot, requiredCount)
		return true
	return false
