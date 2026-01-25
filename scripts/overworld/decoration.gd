extends Node2D
class_name Decoration

@export var storyRequirements: Array[StoryRequirements] = []

@onready var collision: StaticBody2D = get_node_or_null('Collision')

## if true, will start a fadeout animation that then hides this decoration after completing
@export var fadeOutOnRequirementsInvalidated: bool = false

var invisible: bool:
	get:
		return not visible
	set(val):
		visible = not val
		update_collision()

var collisionLayer: int = 1
var collisionMask: int = 1
var fadeoutTween: Tween = null

func _ready():
	if not Engine.is_editor_hint():
		PlayerResources.story_requirements_updated.connect(_story_reqs_updated)
	collisionLayer = collision.collision_layer
	collisionMask = collision.collision_mask
	_story_reqs_updated()

func _story_reqs_updated():
	if Engine.is_editor_hint():
		return
	var storyReqsValid: bool = StoryRequirements.list_is_valid(storyRequirements)
	if fadeOutOnRequirementsInvalidated and visible and not storyReqsValid:
		# fade out this decoration
		fadeoutTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		fadeoutTween.tween_property(self, 'modulate', Color(0, 0, 0, 0), 1.0)
		fadeoutTween.tween_callback(set_decoration_visibility.bind(storyReqsValid))
	else:
		set_decoration_visibility(storyReqsValid)

func set_decoration_visibility(visibility: bool) -> void:
	visible = visibility
	update_collision()
	load_decoration()
	modulate = Color.WHITE
	if fadeoutTween != null:
		fadeoutTween.kill()
		fadeoutTween = null

func update_collision() -> void:
	if collision != null:
		collision.collision_layer = collisionLayer if visible else 0
		collision.collision_mask = collisionMask if visible else 0

func load_decoration():
	pass
