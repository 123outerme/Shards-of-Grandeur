extends Resource
class_name DialogueEntry

@export var entryId: String = ''
@export var items: Array[DialogueItem] = []
@export var storyRequirements: StoryRequirements = null
@export var startsQuest: Quest = null
@export var startsCutscene: Cutscene = null
@export var closesDialogue: bool = false
@export var startsStaticEncounter: StaticEncounter = null

func _init(
	i_id = '',
	i_items: Array[DialogueItem] = [],
	i_storyRequirements = null,
	i_startsQuest = null,
	i_closesDialogue = false,
	i_staticEncounter = null,
):
	entryId = i_id
	items = i_items
	storyRequirements = i_storyRequirements
	startsQuest = i_startsQuest
	closesDialogue = i_closesDialogue
	startsStaticEncounter = i_staticEncounter

func can_use_dialogue() -> bool:
	if storyRequirements != null and not storyRequirements.is_valid():
		return false
	
	if startsQuest != null and not PlayerResources.questInventory.can_start_quest(startsQuest):
		return false
		
	if startsCutscene != null and startsCutscene.storyRequirements != null and not startsCutscene.storyRequirements.is_valid():
		return false
		
	return true
