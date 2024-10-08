@tool
extends Resource
class_name CutsceneCameraMovement

## the movement x/y curves of the camera that define where the camera will go during the frame
@export var movementCurve: AnimCurve2D = null

## the final position the camera will reach at the very end of the movement. initial pos determined by previous frame/state of camera hold
@export var finalPos: Vector2 = Vector2.ZERO

## if true, the `finalPos` is relative to the player. If false, it is a world-space coordinate
@export var relative: bool = false

func _init(
	i_movementCurve: AnimCurve2D = null,
	i_finalPos: Vector2 = Vector2.ZERO,
	i_relative: bool = false,
):
	movementCurve = i_movementCurve
	finalPos = i_finalPos
	relative = i_relative

func get_camera_position_at_time(frameTime: float, totalFrameTime: float, initialPos: Vector2, playerPos: Vector2) -> Vector2:
	var adjustedFinalPos: Vector2 = finalPos
	if relative:
		adjustedFinalPos += playerPos
	return movementCurve.get_position_at_time(frameTime, initialPos, adjustedFinalPos)
