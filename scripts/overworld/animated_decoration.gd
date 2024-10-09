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

func _ready():
	visibleCollisionLayer = staticBody.collision_layer
	visibleCollisionMask = staticBody.collision_mask
	update_collision()

func load_decoration():
	play_animation(animName)

func play_animation(animation: String):
	animSprite.play(animation)

func _on_animated_sprite_2d_animation_finished():
	anim_finished.emit()

func update_collision():
	if staticBody != null:
		staticBody.collision_layer = visibleCollisionLayer if visible else 0
		staticBody.collision_mask = visibleCollisionMask if visible else 0
