@tool
extends NPCScript
class_name MockPlayer

@export var facingLeft: bool:
	get:
		if sprite != null:
			return sprite.flip_h
		return false
	set(value):
		if sprite != null:
			sprite.flip_h = value

@onready var sprite: AnimatedSprite2D = get_node('NPCSprite')
@onready var mockShade: Panel = get_node('MockShade')
@onready var mockShadeCenter: Panel = get_node('MockShade/MockShadeCenter')
