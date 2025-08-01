@tool
extends Decoration
class_name AnimatedDecoration

signal anim_finished

@export var animName: String = 'default'

var visibleCollisionLayer: int = 0b01
var visibleCollisionMask: int = 0b01

var invisible: bool:
	get:
		return not visible
	set(val):
		visible = not val
		update_collision()

@onready var animSprite: AnimatedSprite2D = get_node('AnimatedSprite2D')
@onready var staticBody: StaticBody2D = get_node('Collision')

var currentAnim: String = ''

var disableAnimUpdateOnLoad: bool = false

func _ready():
	super._ready()

func load_decoration() -> void:
	if disableAnimUpdateOnLoad:
		return
	if currentAnim == '':
		currentAnim = animName
	animSprite.set_frame_and_progress(0, 0)
	play_animation(currentAnim)

func update_collision():
	if staticBody != null:
		staticBody.collision_layer = visibleCollisionLayer if visible else 0
		staticBody.collision_mask = visibleCollisionMask if visible else 0

func play_animation(animation: String):
	if animSprite.sprite_frames.has_animation(animation):
		currentAnim = animation
		animSprite.play(animation)
	else:
		pass # print('AnimatedDecoration play_animation WARNING: ', animation, ' is not a known animation')

func get_sprite_frames() -> SpriteFrames:
	return animSprite.sprite_frames

func get_current_animation() -> String:
	return animSprite.animation

func _on_animated_sprite_2d_animation_finished():
	anim_finished.emit()
