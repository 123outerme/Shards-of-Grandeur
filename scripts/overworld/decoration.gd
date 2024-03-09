extends Sprite2D
class_name Decoration

@export var storyRequirements: StoryRequirements = null

@onready var collision: Area2D = get_node('Collision')

func _ready():
	PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	_story_reqs_updated()

func _story_reqs_updated():
	if storyRequirements == null or storyRequirements.is_valid():
		visible = true
		collision.collision_layer = 1
		collision.collision_mask = 1
	else:
		visible = false
		collision.collision_layer = 0
		collision.collision_mask = 0
