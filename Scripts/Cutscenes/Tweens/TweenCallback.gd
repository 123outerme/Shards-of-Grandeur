extends ActorTween
class_name TweenCallback

@export var value: Callable

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_propertyName = '',
	i_easeType = Tween.EASE_IN_OUT,
	i_transitionType = Tween.TRANS_LINEAR,
	i_val = null
):
	super(i_actor, i_isPlayer, i_propertyName, i_easeType, i_transitionType)
	value = i_val
