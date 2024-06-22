extends Resource
class_name CombatantSprite

@export var spriteFrames: SpriteFrames = null
## the largest canvas size of all the SpriteFrames animations
@export var maxSize: Vector2 = Vector2(16, 16)
## how large the animation canvas is normally (in battle_idle animation, specifically)
@export var idleSize: Vector2 = Vector2(16, 16)
## where the center point of the sprite is
@export var centerPosition: Vector2 = Vector2(8, 8)
## where the center of the feet are (position where the feet, if any, would be contacting ground)
@export var feetPosition: Vector2 = Vector2(8, 16)
## if true, the sprite was generated facing right
@export var spriteFacesRight: bool = false
## if largest `idleSize` dimension == 16, use 1. If == 32, use 2. If == 48, use 3.
@export_flags_2d_navigation var navigationLayer: int = 1

func _init(
	i_spriteFrames = null,
	i_maxSize = Vector2(16, 16),
	i_idleSize = Vector2(16, 16),
	i_centerPosition = Vector2(8, 8),
	i_feetPosition = Vector2(8, 16),
	i_facesRight = false,
	i_navLayer = 1,
):
	spriteFrames = i_spriteFrames
	maxSize = i_maxSize
	idleSize = i_idleSize
	centerPosition = i_centerPosition
	feetPosition = i_feetPosition
	spriteFacesRight = i_facesRight
	navigationLayer = i_navLayer
