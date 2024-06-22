extends Decoration
class_name AnimatedDecoration

signal anim_finished

@export var animName: String = 'default'

@onready var animSprite: AnimatedSprite2D = get_node('AnimatedSprite2D')

func load_decoration():
	play_animation(animName)

func play_animation(animation: String):
	animSprite.play(animation)


func _on_animated_sprite_2d_animation_finished():
	anim_finished.emit()
