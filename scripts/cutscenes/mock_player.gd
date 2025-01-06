@tool
extends NPCScript
class_name MockPlayer

const CAM_SHAKING_POSITIONS: Array[Vector2] = [
	Vector2(0,0),
	Vector2(0,2),
	Vector2(0,4),
	Vector2(0,2),
	Vector2(0,0),
	Vector2(0,-2),
	Vector2(0,-4),
	Vector2(0,-2),
]

@export var facingLeft: bool:
	get:
		if sprite != null:
			return sprite.flip_h
		return false
	set(value):
		if sprite != null:
			sprite.flip_h = value

var camShaking: bool = false
var camShakingTime: float = 0
var holdCameraX: bool = false
var holdCameraY: bool = false
var holdCameraPos: Vector2 = Vector2()

@onready var sprite: AnimatedSprite2D = get_node('NPCSprite')
@onready var mockShade: Panel = get_node('MockShade')
@onready var mockShadeCenter: Panel = get_node('MockShade/MockShadeCenter')

func _physics_process(delta):
	if holdCameraX:
		mockShade.position.x = -160 + holdCameraPos.x - position.x
	if holdCameraY:
		mockShade.position.y = -90 + holdCameraPos.y - position.y
	if camShaking:
		camShakingTime += delta
		camShakingTime += delta
		var camShakingIdx: int = (floori(camShakingTime / 0.05) + 1) % len(CAM_SHAKING_POSITIONS)
		var lastShakingIdx: int = (camShakingIdx - 1) % len(CAM_SHAKING_POSITIONS)
		mockShade.position += CAM_SHAKING_POSITIONS[camShakingIdx] - CAM_SHAKING_POSITIONS[lastShakingIdx]

func start_cam_shake():
	camShaking = true
	
func stop_cam_shake():
	camShaking = false
	mockShade.position = Vector2(-160, -90)
	camShakingTime = 0

func hold_camera_at(pos: Vector2, holdX = true, holdY = true):
	holdCameraPos = pos
	holdCameraX = holdX
	holdCameraY = holdY

func snap_camera_back_to_player():
	mockShade.position = Vector2(-160, -90)
	holdCameraX = false
	holdCameraY = false
