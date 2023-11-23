extends ActorTween
class_name TweenFloat

@export var value: float

func _init(
	i_actor = null,
	i_isPlayer = false,
	i_propertyName = '',
	i_easeType = Tween.EASE_IN_OUT,
	i_transitionType = Tween.TRANS_LINEAR,
	i_val = 0.0
):
	super(i_actor, i_isPlayer, i_propertyName, i_easeType, i_transitionType)
	value = i_val
