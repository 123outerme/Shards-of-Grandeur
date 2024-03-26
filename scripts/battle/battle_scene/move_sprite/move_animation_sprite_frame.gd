extends Resource
class_name MoveAnimSpriteFrame

enum MoveSpriteTarget {
	GLOBAL = 0,
	TARGET = 1,
	USER = 2,
	TARGET_TEAM = 3,
	USER_TEAM = 4
}

enum MoveSpriteOffset {
	NONE = 0,
	IN_FRONT = 1,
	BEHIND = 2,
	ABOVE = 3,
	BELOW = 4
}

@export_multiline var annotation: String = ''
@export var animation: String = ''
@export var duration: float = 1
@export var speed: float = 1
@export var relativeTo: MoveSpriteTarget = MoveSpriteTarget.GLOBAL
@export var position: Vector2
@export_flags('In Front', 'Behind', 'Above', 'Below') var offset: int = MoveSpriteOffset.NONE
@export var xCurve: Curve = Curve.new()
@export var yCurve: Curve = Curve.new()
@export var particles: ParticlePreset = null

func _init(
	i_annotation = '',
	i_animation = '',
	i_duration = 1,
	i_speed = 1,
	i_relativeTo = MoveSpriteTarget.GLOBAL,
	i_pos = Vector2(),
	i_offset = MoveSpriteOffset.NONE,
	i_xCurve = Curve.new(),
	i_yCurve = Curve.new(),
	i_particles = null,
):
	annotation = i_annotation
	animation = i_animation
	speed = i_speed
	relativeTo = i_relativeTo
	position = i_pos
	offset = i_offset
	xCurve = i_xCurve
	yCurve = i_yCurve
	particles = i_particles

func get_real_duration(diff: Vector2):
	if speed <= 0 or diff.length() == 0:
		return duration
	
	return min(diff.length() / speed, duration)

func get_percent_complete(time: float, diff: Vector2) -> float:
	if duration <= 0:
		return 1
	return time / get_real_duration(diff)

func get_x_curve_pos(time: float, diff: Vector2) -> float:
	return xCurve.sample_baked(get_percent_complete(time, diff))

func get_y_curve_pos(time: float, diff: Vector2) -> float:
	return yCurve.sample_baked(get_percent_complete(time, diff))

func get_sprite_position(time: float, targetPos: Vector2, startPos: Vector2) -> Vector2:
	var diff = targetPos - startPos
	return Vector2(startPos.x + (diff.x * get_x_curve_pos(time, diff)), startPos.y + (diff.y * get_y_curve_pos(time, diff)))
