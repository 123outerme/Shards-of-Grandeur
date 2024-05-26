extends Resource
class_name ActorFaceTarget

@export var actorTreePath: String = ''
@export var isPlayer: bool = false
@export var targetTreePath: String = ''
@export var targetPosition: Vector2 = Vector2.ZERO
@export var targetIsPlayer: bool = false

func _init(
	i_actorTreePath = '',
	i_isPlayer = false,
	i_targetTreePath = '',
	i_targetPosition = Vector2.ZERO,
	i_targetIsPlayer = false,
):
	actorTreePath = i_actorTreePath
	isPlayer = i_isPlayer
	targetTreePath = i_targetTreePath
	targetPosition = i_targetPosition
	targetIsPlayer = i_targetIsPlayer
