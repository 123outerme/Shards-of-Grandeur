extends Resource
class_name ActorSpriteAnim

@export var actorTreePath: String = ''
@export var isPlayer: bool = false
@export var animation: String = ''

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_animation = '',
):
	actorTreePath = i_actor
	isPlayer = i_isPlayer
	animation = i_animation
