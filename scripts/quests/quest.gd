extends Resource
class_name Quest

@export_category("Quest - Details")

@export var questName: String

@export_multiline var description: String

@export var steps: Array[QuestStep]

@export var storyRequirements: StoryRequirements

## if true, is marked with the main quest icon in the quests panel
@export var isMainQuest: bool = false

## if true, increments the act number after the last step is completed
@export var advanceActActerComplete: bool = false

func _init(
	i_name = '',
	i_description = '',
	i_steps: Array[QuestStep] = [],
	i_storyRequirements = null,
	i_mainQuest = false,
	i_advanceAct = false,
):
	questName = i_name
	description = i_description
	steps = i_steps
	storyRequirements = i_storyRequirements
	isMainQuest = i_mainQuest
	advanceActActerComplete = i_advanceAct
