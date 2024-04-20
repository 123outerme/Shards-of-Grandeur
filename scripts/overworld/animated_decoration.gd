extends Decoration
class_name AnimatedDecoration

@export var animName: String = 'default'

@onready var animSprite: AnimatedSprite2D = get_node('AnimatedSprite2D')

func load_decoration():
	animSprite.play(animName)
