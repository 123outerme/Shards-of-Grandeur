extends Resource
class_name ActorSpriteAnim

@export var actor: Node2D
@export var isPlayer: bool = false
@export var animation: String = ''

func _init(
	i_actor = null,
	i_isPlayer = false,
	i_animation = '',
):
	actor = i_actor
	isPlayer = i_isPlayer
	animation = i_animation
