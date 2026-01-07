extends Resource
class_name MoveAnimSprite

@export var spriteFrames: SpriteFrames = null

## if false, the top-left of the sprite will be displayed at (0,0) of the MoveSprite object's object space
@export var centerSprite: bool = true

## the canvas size of the animation
@export var maxSize: Vector2 = Vector2(16, 16)

@export var frames: Array[MoveAnimSpriteFrame] = []

## if true, waits to start playing until after the combatant repositions
@export var delayedUntilReposition: bool = false

## if true, waits to start playing until the impact frame arrives
@export var playsOnImpactFrame: bool = true

## if true, spawns one of these sprites per combatant being targeted
@export var onePerTarget: bool = true

## if true, displays the sprite on a layer behind the combatants
@export var behindCombatants: bool = false

func _init(
	i_spriteFrames = null,
	i_centerSprite: bool = true,
	i_maxSize = Vector2(16, 16),
	i_frames: Array[MoveAnimSpriteFrame] = [],
	i_delayed: bool = false,
	i_playsOnImpact: bool = true,
	i_onePerTarget: bool = true,
	i_behindCombatants: bool = false,
):
	spriteFrames = i_spriteFrames
	centerSprite = i_centerSprite
	maxSize = i_maxSize
	frames = i_frames
	delayedUntilReposition = i_delayed
	playsOnImpactFrame = i_playsOnImpact
	onePerTarget = i_onePerTarget
	behindCombatants = i_behindCombatants
