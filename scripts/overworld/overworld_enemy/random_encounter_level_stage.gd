extends Resource
class_name RandomEncounterLevelStage

@export var storyRequirements: Array[StoryRequirements] = []

@export var minLevel: int = 1
@export var maxLevel: int = 1

func _init(
	i_storyRequirements: Array[StoryRequirements] = [],
	i_minLevel: int = 1,
	i_maxLevel: int = 1,
):
	storyRequirements = i_storyRequirements
	minLevel = i_minLevel
	maxLevel = i_maxLevel

func is_valid() -> bool:
	return StoryRequirements.list_is_valid(storyRequirements)
