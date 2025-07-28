extends TextureRect
class_name StoryReqsTextureRect

@export var storyRequirements: Array[StoryRequirements] = []
@export var validateOnReady: bool = true
@export var validateOnStoryReqsUpdate: bool = true

func _ready() -> void:
	if validateOnReady:
		validate()
	PlayerResources.story_requirements_updated.connect(_story_reqs_updated)

func validate() -> void:
	visible = StoryRequirements.list_is_valid(storyRequirements)

func _story_reqs_updated() -> void:
	if validateOnStoryReqsUpdate:
		validate()
