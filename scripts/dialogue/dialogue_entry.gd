extends Resource
class_name DialogueEntry

## not mandatory, but is required if this dialogue is required for a SaveRequirements
@export var entryId: String = ''

@export var items: Array[DialogueItem] = []

## requirements to see this dialogue
@export var storyRequirements: StoryRequirements = null

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
	if storyRequirements != null and not storyRequirements.is_valid():
		return false
	
	if startsQuest != null and not PlayerResources.questInventory.can_start_quest(startsQuest):
		return false
	
	if startsCutscene != null and startsCutscene.storyRequirements != null and not startsCutscene.storyRequirements.is_valid():
		return false
	
	return true
