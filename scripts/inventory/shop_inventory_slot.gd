extends InventorySlot
class_name ShopInventorySlot

@export var storyRequirements: StoryRequirements = null
@export var buyableStoryReqs: StoryRequirements = null
@export var sinceVersion: String = ''

func _init(
	i: Item = null,
	i_count = 1,
	i_storyRequirements = null,
	i_buyableStoryReqs = null,
	i_sinceVersion = ''):
	super(i, i_count)
	storyRequirements = i_storyRequirements
	buyableStoryReqs = i_buyableStoryReqs
	sinceVersion = i_sinceVersion

func is_valid() -> bool:
	if storyRequirements == null:
		return true
	return storyRequirements.is_valid()

func should_add(saveVersion: String) -> bool:
	# add if it's new to this version
	return saveVersion == sinceVersion or GameSettings.get_version_differences_between(sinceVersion, saveVersion) != GameSettings.VersionDiffs.NONE
