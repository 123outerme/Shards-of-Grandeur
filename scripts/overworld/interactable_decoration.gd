@tool
extends Interactable
class_name InteractableDecoration

@export var interactAnim: String = ''

@onready var animatedDecoration: AnimatedDecoration = get_node('AnimatedDecoration')
@onready var interactSprite: AnimatedSprite2D = get_node('InteractSprite')

var invisible: bool:
	set(i):
		visible = not i
		if animatedDecoration != null:
			animatedDecoration.invisible = i
	get:
		return not visible

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		super._ready()
		animatedDecoration.anim_finished.connect(animatedDecoration.play_animation.bind(animatedDecoration.animName))
		show_interact_sprite(false)

func show_interact_sprite(showSprite: bool = true):
	interactSprite.visible = showSprite
	if showSprite:
		interactSprite.play('default')
	else:
		interactSprite.stop()

func play_animation(animName: String):
	if animName != '':
		animatedDecoration.play_animation(animName)

func interact(args: Array = []):
	if interactAnim != '':
		animatedDecoration.play_animation(interactAnim)
	super.interact(args)

func _on_area_entered(area):
	if area.name == 'PlayerEventCollider':
		show_interact_sprite()
		enter_player_range()

func _on_area_exited(area):
	if area.name == 'PlayerEventCollider' and self in PlayerFinder.player.interactables:
		show_interact_sprite(false)
		exit_player_range()
