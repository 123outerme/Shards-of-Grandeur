@tool
extends Resource
class_name AnimCurve2D

## curve shape of the X value from t=0 (start time) to t=1 (end time)
@export var curveX: Curve = null

## curve shape of the Y value from t=0 (start time) to t=1 (end time)
@export var curveY: Curve = null

## if true, overrides curveX/curveY values and simply provides linear interpolation from t=0 to t=1
@export var linearInterp: bool = false

func _init(
	i_curveX: Curve = null,
	i_curveY: Curve = null,
	i_lerp: bool = false
):
	curveX = i_curveX
	if curveX != null:
		curveX.bake()
	curveY = i_curveY
	if curveY != null:
		curveY.bake()
	linearInterp = i_lerp

func get_position_at_time(percentTime: float, initialPos: Vector2, finalPos: Vector2) -> Vector2:
	percentTime = min(1, max(0, percentTime)) # bound percentTime between 0 and 1
	var diff: Vector2 = (finalPos - initialPos)
	
	if linearInterp:
		return initialPos + diff * percentTime
	else:
		var pos: Vector2 = Vector2.ZERO
		pos.x = curveX.sample_baked(percentTime)
		pos.y = curveY.sample_baked(percentTime)
		return initialPos + Vector2(diff.x * pos.x, diff.y * pos.y)
