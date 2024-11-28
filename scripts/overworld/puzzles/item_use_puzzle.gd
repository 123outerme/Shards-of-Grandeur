extends Puzzle
class_name ItemUsePuzzle

@export var item: Item = null
@export var requiredCount: int = 1
@export var consumeItem: bool = true

func _init(
	i_id = '',
	i_prereqRequirements: Array[StoryRequirements] = [],
	i_item: Item = null,
	i_requiredCount = 1,
	i_consumeItem: bool = true,
):
	super(i_id, i_prereqRequirements)
	item = i_item
	requiredCount = i_requiredCount
	consumeItem = i_consumeItem

func passes_prereqs() -> bool:
	if is_solved():
		return true
	if not super.passes_prereqs():
		return false
	var inventorySlot: InventorySlot = PlayerResources.inventory.get_slot_for_item(item)
	return inventorySlot != null and inventorySlot.count >= requiredCount

func solve():
	var inventorySlot: InventorySlot = PlayerResources.inventory.get_slot_for_item(item)
	if inventorySlot != null and inventorySlot.count >= requiredCount:
		if consumeItem:
			PlayerResources.inventory.trash_item(inventorySlot, requiredCount)
		super.solve()
