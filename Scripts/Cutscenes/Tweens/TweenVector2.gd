extends ActorTween
class_name TweenVector2

@export var value: Vector2

func _init(
	i_actor = '',
	i_isPlayer = false,
	i_propertyName = '',
	i_easeType = Tween.EASE_IN_OUT,
	i_transitionType = Tween.TRANS_LINEAR,
	i_val = Vector2()
):
	super(i_actor, i_isPlayer, i_propertyName, i_easeType, i_transitionType)
	value = i_val
