extends Resource
class_name CombatantSprite

@export var spriteFrames: SpriteFrames = null
@export var combatantOverworld: CombatantOverworld = null

## the largest canvas size of all the SpriteFrames animations
@export var maxSize: Vector2 = Vector2(16, 16)

## how large the animation canvas is normally (in battle_idle animation, specifically)
@export var idleSize: Vector2 = Vector2(16, 16)

## where the center point of the sprite is
@export var centerPosition: Vector2 = Vector2(8, 8)

## where the center point of the canvas portion for only the battle_idle animation. Used for centering combatants in idle animation in UIs
@export var idleCanvasCenterPosition: Vector2 = Vector2(8, 8)

## where the center of the feet are (position where the feet, if any, would be contacting ground)
@export var feetPosition: Vector2 = Vector2(8, 16)

## where the center of the head is (position where head-seeking moves would land)
@export var headPosition: Vector2 = Vector2(8, 4)

## if true, the sprite was generated facing right
@export var spriteFacesRight: bool = false

## if largest `idleSize` dimension == 16, use 1. If == 32, use 2. If == 48, use 3.
@export_flags_2d_navigation var navigationLayer: int = 1

@export_category('Start Move Frames')
## the frame tweening towards a target starts for the "attack_affinity" animation
@export var attackAffinityStartMoveFrame: int = 0

## the frame tweening towards a target starts for the "attack_magic" animation
@export var attackMagicStartMoveFrame: int = 0

## the frame tweening towards a target starts for the "attack_phys" animation
@export var attackPhysStartMoveFrame: int = 0

@export_category('Arrival Frames')
## the "arrival" frame for the "attack_affinity" animation of this combatant. Tweening towards a target combatant use this for timing purposes. 0-indexed, <0 means auto-timed. Frames are counted by amount of time per frame, not by which sprite is being displayed (for cases of frames with increased duration)
@export var attackAffinityArrivalFrame: int = -1

## the "arrival" frame for the "attack_magic" animation of this combatant. Tweening towards a target combatant use this for timing purposes. 0-indexed, <0 means auto-timed. Frames are counted by amount of time per frame, not by which sprite is being displayed (for cases of frames with increased duration)
@export var attackMagicArrivalFrame: int = -1

## the "arrival" frame for the "attack_phys" animation of this combatant. Tweening towards a target combatant use this for timing purposes. 0-indexed, <0 means auto-timed. Frames are counted by amount of time per frame, not by which sprite is being displayed (for cases of frames with increased duration)
@export var attackPhysArrivalFrame: int = -1

@export_category('Impact Frames')
## the "impact" frame for the "attack_affinity" animation of this combatant. Certain moves use this for timing purposes. 0-indexed, <0 means auto-timed. Frames are counted by amount of time per frame, not by which sprite is being displayed (for cases of frames with increased duration)
@export var attackAffinityImpactFrame: int = -1

## the "impact" frame for the "attack_magic" animation of this combatant. Certain moves use this for timing purposes. 0-indexed, <0 means auto-timed. Frames are counted by amount of time per frame, not by which sprite is being displayed (for cases of frames with increased duration)
@export var attackMagicImpactFrame: int = -1

## the "impact" frame for the "attack_phys" animation of this combatant. Certain moves use this for timing purposes. 0-indexed, <0 means auto-timed. Frames are counted by amount of time per frame, not by which sprite is being displayed (for cases of frames with increased duration)
@export var attackPhysImpactFrame: int = -1

func _init(
	i_spriteFrames = null,
	i_combatantOverworld = null,
	i_maxSize = Vector2(16, 16),
	i_idleSize = Vector2(16, 16),
	i_centerPosition = Vector2(8, 8),
	i_feetPosition = Vector2(8, 16),
	i_headPosition = Vector2(8, 4),
	i_facesRight = false,
	i_navLayer = 1,
	i_attackPhysImpactFrame = -1,
	i_attackMagicImpactFrame = -1,
	i_attackAffinityImpactFrame = -1,
	i_attackPhysArrivalFrame = -1,
	i_attackMagicArrivalFrame = -1,
	i_attackAffinityArrivalFrame = -1,
):
	spriteFrames = i_spriteFrames
	combatantOverworld = i_combatantOverworld
	maxSize = i_maxSize
	idleSize = i_idleSize
	centerPosition = i_centerPosition
	feetPosition = i_feetPosition
	headPosition = i_headPosition
	spriteFacesRight = i_facesRight
	navigationLayer = i_navLayer
	attackPhysImpactFrame = i_attackPhysImpactFrame
	attackMagicImpactFrame = i_attackMagicImpactFrame
	attackAffinityImpactFrame = i_attackAffinityImpactFrame
	attackPhysArrivalFrame = i_attackPhysArrivalFrame
	attackMagicArrivalFrame = i_attackMagicArrivalFrame
	attackAffinityArrivalFrame = i_attackAffinityArrivalFrame

func get_start_move_frame(animName: String) -> int:
	match animName:
		'attack_phys':
			return attackPhysStartMoveFrame
		'attack_magic':
			return attackMagicStartMoveFrame
		'attack_affinity':
			return attackAffinityStartMoveFrame
	return 0

func get_impact_frame(animName: String) -> int:
	match animName:
		'attack_phys':
			return attackPhysImpactFrame
		'attack_magic':
			return attackMagicImpactFrame
		'attack_affinity':
			return attackAffinityImpactFrame
	return -1

func get_arrive_frame(animName: String) -> int:
	match animName:
		'attack_phys':
			return attackPhysArrivalFrame
		'attack_magic':
			return attackMagicArrivalFrame
		'attack_affinity':
			return attackAffinityArrivalFrame
	return -1
