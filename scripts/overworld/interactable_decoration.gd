extends Interactable
class_name InteractableDecoration

@export var interactAnim: String = ''

@onready var animatedDecoration: AnimatedDecoration = get_node('AnimatedDecoration')
@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func interact(args: Array = []):
	animatedDecoration.play_animation(interactAnim)
	animatedDecoration.anim_finished.connect(animatedDecoration.play_animation.bind(animatedDecoration.animName))
	super.interact(args)
