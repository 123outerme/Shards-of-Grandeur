extends Resource
class_name CombatantSprite

@export var spriteFrames: SpriteFrames = null
@export var maxSize: Vector2 = Vector2(16, 16)
@export var idleSize: Vector2 = Vector2(16, 16)
@export var centerPosition: Vector2 = Vector2(8, 8)
@export var feetPosition: Vector2 = Vector2(8, 16)
@export var spriteFacesRight: bool = false
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
