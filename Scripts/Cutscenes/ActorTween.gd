extends Resource
class_name ActorTween

@export var actorTreePath: String = ''
@export var isPlayer: bool = false
@export var propertyName: String = ''
@export var easeType: Tween.EaseType = Tween.EASE_IN_OUT
@export var transitionType: Tween.TransitionType = Tween.TRANS_LINEAR

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_propertyName = '',
	i_easeType = Tween.EASE_IN_OUT,
	i_transitionType = Tween.TRANS_LINEAR,
):
	actorTreePath = i_actor
	isPlayer = i_isPlayer
	propertyName = i_propertyName
	easeType = i_easeType
	transitionType = i_transitionType
