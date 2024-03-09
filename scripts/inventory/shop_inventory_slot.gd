extends InventorySlot
class_name ShopInventorySlot

@export var storyRequirements: StoryRequirements = null

func _init(i: Item = null, i_count = 1, i_storyRequirements = null):
	super(i, i_count)
	storyRequirements = i_storyRequirements

func is_valid() -> bool:
	if storyRequirements == null:
		return true
	return storyRequirements.is_valid()
