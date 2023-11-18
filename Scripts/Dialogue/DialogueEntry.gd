extends Resource
class_name DialogueEntry

@export var entryId: String = ''
@export var items: Array[DialogueItem] = []
@export var storyRequirements: StoryRequirements = null
@export var startsQuest: Quest = null

func _init(
	i_id = '',
	i_items: Array[DialogueItem] = [],
	i_storyRequirements = null,
	i_startsQuest = null,
):
	entryId = i_id
	items = i_items
	storyRequirements = i_storyRequirements
	startsQuest = i_startsQuest

func can_use_dialogue() -> bool:
	if storyRequirements != null and not storyRequirements.is_valid():
		return false
	
	if startsQuest != null and not PlayerResources.questInventory.can_start_quest(startsQuest):
		return false
	
	return true
