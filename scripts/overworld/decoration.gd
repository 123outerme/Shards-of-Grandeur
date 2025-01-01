extends Node2D
class_name Decoration

@export var storyRequirements: StoryRequirements = null

@onready var collision: StaticBody2D = get_node_or_null('Collision')

var collisionLayer = 1
var collisionMask = 1

func _ready():
	if not Engine.is_editor_hint():
		PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	collisionLayer = collision.collision_layer
	collisionMask = collision.collision_mask
	_story_reqs_updated()

func _story_reqs_updated():
	if Engine.is_editor_hint():
		return
	
	var pastVisible: bool = visible
	if storyRequirements == null or storyRequirements.is_valid():
		visible = true
	else:
		visible = false
	load_decoration()

func update_collision() -> void:
	if collision != null:
		collision.collision_layer = collisionLayer if visible else 0
		collision.collision_mask = collisionMask if visible else 0

func load_decoration():
	pass
