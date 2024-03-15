extends Control
class_name OrbUnitDisplay

@export var unfilledOrbSprite: Texture2D = null
@export var filledOrbSprite: Texture2D = null
@export var filledOrb: bool = false

@onready var sprite: Sprite2D = get_node('Sprite2D')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_orb_unit_display()

func load_orb_unit_display():
	sprite.texture = filledOrbSprite if filledOrb else unfilledOrbSprite
