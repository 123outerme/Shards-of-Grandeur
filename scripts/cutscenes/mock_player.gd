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

@onready var sprite: AnimatedSprite2D = get_node('NPCSprite')
@onready var mockShade: Panel = get_node('MockShade')
@onready var mockShadeCenter: Panel = get_node('MockShade/MockShadeCenter')

func _process(delta):
	if camShaking:
		camShakingTime += delta
		var camShakingIdx = floori(camShakingTime / 0.05) % len(CAM_SHAKING_POSITIONS)
		mockShade.position = Vector2(-160, -120) + CAM_SHAKING_POSITIONS[camShakingIdx]

func start_cam_shake():
	camShaking = true
	
func stop_cam_shake():
	camShaking = false
	mockShade.position = Vector2(-160, -120)
	camShakingTime = 0
