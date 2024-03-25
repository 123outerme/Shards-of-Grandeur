extends Resource
class_name MoveAnimSprite

@export var spriteFrames: SpriteFrames = null
@export var maxSize: Vector2 = Vector2(16, 16)
@export var frames: Array[MoveAnimSpriteFrame] = []
@export var delayedUntilReposition: bool = false
@export var onePerTarget: bool = true

func _init(
	i_spriteFrames = null,
	i_maxSize = Vector2(16, 16),
	i_frames: Array[MoveAnimSpriteFrame] = [],
	i_delayed = false,
	i_onePerTarget = true,
):
	spriteFrames = i_spriteFrames
	maxSize = i_maxSize
	frames = i_frames
	delayedUntilReposition = i_delayed
	onePerTarget = i_onePerTarget
