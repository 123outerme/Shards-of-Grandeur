extends Resource
class_name ActorAnimSet

@export var actorTreePath: String = ''
@export var isPlayer: bool = false
@export var spriteState: String = 'default'

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_spriteState = 'default',
):
	actorTreePath = i_actor
	isPlayer = i_isPlayer
	spriteState = i_spriteState
