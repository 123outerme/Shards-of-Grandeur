extends Control
class_name ToolStoryReqsEditor

@export var storyReqs: StoryRequirements = null

@onready var minActSpinBox: SpinBox = get_node('TabContainer/Act/MinActControl/MinAct')
@onready var maxActSpinBox: SpinBox = get_node('TabContainer/Act/MaxActControl/MaxAct')

func _ready() -> void:
	load_story_reqs_editor()

func load_story_reqs_editor() -> void:
	if storyReqs != null:
		minActSpinBox.value = storyReqs.minAct
		maxActSpinBox.value = storyReqs.maxAct

func save_story_reqs() -> StoryRequirements:
	var reqs: StoryRequirements = StoryRequirements.new(
		int(minActSpinBox.value),
		int(maxActSpinBox.value),
	)
	return reqs
