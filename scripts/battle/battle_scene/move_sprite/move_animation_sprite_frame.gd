extends Resource
class_name MoveAnimSpriteFrame

enum MoveSpriteTarget {
	GLOBAL = 0,
	TARGET = 1,
	USER = 2,
	TARGET_TEAM = 3,
	USER_TEAM = 4,
	CURRENT_POSITION = 5,
}

## actual set value is 2^offset, these values are used for bit-shifting to test which flags are set
enum MoveSpriteOffset { 
	NONE = 0,
	IN_FRONT = 1,
	BEHIND = 2,
	ABOVE = 3,
	BELOW = 4,
	HEAD = 5,
}

@export_group('')

## editor use only; documents what's happening in this frame
@export_multiline var annotation: String = ''

## SpriteFrames animation name to play; `#stop` to stop playing animations, and `default` for blank frame
@export var animation: String = ''

## duration in seconds
@export var duration: float = 1

## speed of sprite movement; sets a maximum duration based on the difference in sprite positions (safe to ignore completely in reasonable use cases)
@export var speed: float = 1

## opacity of the sprite/particles
@export var opacity: float = 1

## pivot point of the sprite, for rotation; shifts the sprite this much as well. MoveSprite does not remember previous pivots from previous frames
@export var spritePivot: Vector2 = Vector2.ZERO

@export_group('Position')

## which entity/marked position this position offset is relative to
@export var relativeTo: MoveSpriteTarget = MoveSpriteTarget.CURRENT_POSITION

## the offset from the `relativeTo` to move the sprite to over the course of the frame
@export var position: Vector2

## Offsets based on target entity's size. If the first four bits are set, will play at the VISUAL center of the target sprite, not the configured CombatantSprite center. If the 5th bit is set, all others are ignored.
@export_flags('In Front', 'Behind', 'Above', 'Below', 'Head') var offset: int = MoveSpriteOffset.NONE

## describes the x position of the sprite over the duration of the frame
@export var xCurve: Curve = Curve.new()

## describes the y position of the sprite over the duration of the frame
@export var yCurve: Curve = Curve.new()

@export_group('Rotation')

## if true, will rotate the sprite
@export var rotate: bool = false

## target entity/marked position to face towards
@export var rotateToFace: MoveSpriteTarget = MoveSpriteTarget.TARGET

## position offsetted from the `rotateToFace` target to face towards
@export var rotateToFacePosition: Vector2

## Offset based on the target entity's size
@export_flags('In Front', 'Behind', 'Above', 'Below') var rotateToFaceOffset: int = MoveSpriteOffset.NONE

## If true, will constantly update the rotation to track the target position as the frame progresses
@export var trackRotationTarget: bool = false

@export_group('')

## particles to play on this frame
@export var particles: ParticlePreset = null

## sfx to play on this frame
@export var sfx: AudioStream = null

## if true, will have the AudioHandler slightly randomize the SFX's pitch
@export var randomizeSfxPitch: bool = false

## if true, emits the complete event for the MoveSprite when this frame is STARTED, rather than when it's ENDED. The rest of the frames in the animation will play on and then the sprite will be freed.
@export var emitCompleteOnStart: bool = false

func _init(
	i_annotation: String = '',
	i_animation: String = '',
	i_duration: float = 1,
	i_speed: float = 1,
	i_relativeTo: MoveSpriteTarget = MoveSpriteTarget.CURRENT_POSITION,
	i_pos: Vector2 = Vector2(),
	i_offset: MoveSpriteOffset = MoveSpriteOffset.NONE,
	i_xCurve: Curve = Curve.new(),
	i_yCurve: Curve = Curve.new(),
	i_rotate: bool = false,
	i_rotateToFace: MoveSpriteTarget = MoveSpriteTarget.TARGET,
	i_rotateToFacePos: Vector2 = Vector2(),
	i_spritePivot: Vector2 = Vector2.ZERO,
	i_rotateToFaceOffset: MoveSpriteOffset = MoveSpriteOffset.NONE,
	i_trackRotationTarget: bool = false,
	i_particles: ParticlePreset = null,
	i_sfx: AudioStream = null,
	i_randomizeSfxPitch: bool = false,
	i_emitCompleteOnStart: bool = false,
):
	annotation = i_annotation
	animation = i_animation
	duration = i_duration
	speed = i_speed
	relativeTo = i_relativeTo
	position = i_pos
	offset = i_offset
	xCurve = i_xCurve
	yCurve = i_yCurve
	rotate = i_rotate
	rotateToFace = i_rotateToFace
	rotateToFacePosition = i_rotateToFacePos
	rotateToFaceOffset = i_rotateToFaceOffset
	spritePivot = i_spritePivot
	trackRotationTarget = i_trackRotationTarget
	particles = i_particles
	sfx = i_sfx
	randomizeSfxPitch = i_randomizeSfxPitch
	emitCompleteOnStart = i_emitCompleteOnStart

func get_real_duration(diff: Vector2):
	if speed <= 0 or diff.length() == 0:
		return duration
	
	return min(diff.length() / speed, duration)

func get_percent_complete(time: float, diff: Vector2) -> float:
	if duration <= 0:
		return 1
	return time / get_real_duration(diff)

func get_x_curve_pos(time: float, diff: Vector2) -> float:
	var percentComplete: float = get_percent_complete(time, diff)
	if xCurve == null or percentComplete == 1:
		return percentComplete # default: linear, also bail out if already complete
	return xCurve.sample_baked(get_percent_complete(time, diff))

func get_y_curve_pos(time: float, diff: Vector2) -> float:
	var percentComplete: float = get_percent_complete(time, diff)
	if yCurve == null or percentComplete == 1:
		return percentComplete # default: linear, also bail out if already complete
	return yCurve.sample_baked(get_percent_complete(time, diff))

func get_sprite_position(time: float, targetPos: Vector2, startPos: Vector2) -> Vector2:
	var diff = targetPos - startPos
	return Vector2(startPos.x + (diff.x * get_x_curve_pos(time, diff)), startPos.y + (diff.y * get_y_curve_pos(time, diff)))

func get_sprite_opacity(currentOpacity: float, time: float, targetPos: Vector2, startPos: Vector2) -> float:
	var diff = targetPos - startPos
	return (opacity - currentOpacity) * get_percent_complete(time, diff) + currentOpacity

func get_sprite_pivot(time: float, targetPos: Vector2, startPos: Vector2) -> Vector2:
	startPos.x *= -1 # because we're flipping x here to make the data inputting make more sense, we have to account for a startPos with a flipped x
	var diff = targetPos - startPos
	return Vector2((startPos.x + (diff.x * (time / duration))) * -1, startPos.y + (diff.y * (time / duration)))
