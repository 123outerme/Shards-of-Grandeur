extends TextureRect
class_name MapOverlayLayer

@export var storyRequirements: Array[StoryRequirements] = []

func _ready() -> void:
	validate()

func validate() -> void:
	visible = StoryRequirements.list_is_valid(storyRequirements)
