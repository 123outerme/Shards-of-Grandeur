extends Resource
class_name ActorAnimSet

@export var actorTreePath: String = ''
@export var isPlayer: bool = false
@export var animationSet: SpriteFrames

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_animationSet = null,
):
	actorTreePath = i_actor
	isPlayer = i_isPlayer
	animationSet = i_animationSet
