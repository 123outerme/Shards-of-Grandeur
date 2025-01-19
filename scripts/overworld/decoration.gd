extends Node2D
class_name Decoration

@export var storyRequirements: Array[StoryRequirements] = []

@onready var collision: StaticBody2D = get_node_or_null('Collision')

var collisionLayer: int = 1
var collisionMask: int = 1

func _ready():
	if not Engine.is_editor_hint():
		PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	collisionLayer = collision.collision_layer
	collisionMask = collision.collision_mask
	_story_reqs_updated()

func _story_reqs_updated():
	if Engine.is_editor_hint():
		return
	
	visible = StoryRequirements.list_is_valid(storyRequirements)
	update_collision()
	load_decoration()

func update_collision() -> void:
	if collision != null:
		collision.collision_layer = collisionLayer if visible else 0
		collision.collision_mask = collisionMask if visible else 0

func load_decoration():
	pass
