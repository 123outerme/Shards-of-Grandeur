extends Resource
class_name Quest

@export_category("Quest - Details")
@export var questName: String
@export_multiline var description: String
@export var steps: Array[QuestStep]
@export var storyRequirements: StoryRequirements

func _init(
	i_name = '',
	i_description = '',
	i_steps: Array[QuestStep] = [],
	i_storyRequirements = null,
):
	questName = i_name
	description = i_description
	steps = i_steps
	storyRequirements = i_storyRequirements
