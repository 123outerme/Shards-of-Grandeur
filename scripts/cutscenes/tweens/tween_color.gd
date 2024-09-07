extends ActorTween
class_name TweenColor

@export var value: Color = Color()

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_propertyName = '',
	i_easeType = Tween.EASE_IN_OUT,
	i_transitionType = Tween.TRANS_LINEAR,
	i_val = Color()
):
	super(i_actor, i_isPlayer, i_propertyName, i_easeType, i_transitionType)
	value = i_val
