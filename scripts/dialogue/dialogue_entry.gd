extends Resource
class_name DialogueEntry

## not mandatory, but is required if this dialogue is required for a SaveRequirements
@export var entryId: String = ''

@export var items: Array[DialogueItem] = []

## requirements to see this dialogue (OR'd with all of the below `ordStoryRequirements`)
@export var storyRequirements: StoryRequirements = null

## additional story requirements to see this dialogue (OR'd with each other and the above `storyRequirements`)
@export var ordStoryRequirements: Array[StoryRequirements] = []

## after this dialogue is over, starts the provided quest. If this quest can't be started, this dialogue won't be played
@export var startsQuest: Quest = null

## after this dialogue is over, starts the provided cutscene. If this cutscene can't be played, this dialogue won't be used
@export var startsCutscene: Cutscene = null

## after this dialogue is over, gives the provided item
@export var givesItem: Item = null

## if true, after this dialogue is over, all queued dialogues get dropped and the text box closes
@export var closesDialogue: bool = false

## if true, after this dialogue is over, fully heals the player
@export var fullHealsPlayer: bool = false

## if true, after this dialogue is over, starts a static encounter
@export var startsStaticEncounter: StaticEncounter = null

func _init(
	i_id = '',
	i_items: Array[DialogueItem] = [],
	i_storyRequirements = null,
	i_startsQuest = null,
	i_givesItem = null,
	i_closesDialogue = false,
	i_fullHealsPlayer = false,
	i_staticEncounter = null,
):
	entryId = i_id
	items = i_items
	storyRequirements = i_storyRequirements
	startsQuest = i_startsQuest
	givesItem = i_givesItem
	closesDialogue = i_closesDialogue
	fullHealsPlayer = i_fullHealsPlayer
	startsStaticEncounter = i_staticEncounter

func can_use_dialogue() -> bool:
	var requirements: Array[StoryRequirements] = [storyRequirements]
	requirements.append_array(ordStoryRequirements)
	requirements = requirements.filter(func(req): return req != null)
	
	var isOneReqValid: bool = len(requirements) == 0 
	for req: StoryRequirements in requirements:
		if req != null and req.is_valid():
			isOneReqValid = true
			break
	if not isOneReqValid:
		return false
	
	if startsQuest != null and not PlayerResources.questInventory.can_start_quest(startsQuest):
		return false
	
	if startsCutscene != null and startsCutscene.storyRequirements != null and not startsCutscene.storyRequirements.is_valid():
		return false
	
	return true
