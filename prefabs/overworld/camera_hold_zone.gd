extends Area2D
class_name CameraHoldZone

@export var holdX: bool = true
@export var holdY: bool = true
@export var disabled: bool = false
@export var usePlayerWarpCamMarker: bool = false

@onready var playerWarpCamPos: Marker2D = get_node('PlayerWarpCamPos')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_area_entered(area: Area2D):
	if area.name == 'PlayerEventCollider' and not disabled and not PlayerFinder.player.inCutscene and not SceneLoader.cutscenePlayer.playing:
		#print('hold camera!')
		var pos = (position + playerWarpCamPos.position) \
				if PlayerFinder.player.disableMovement and playerWarpCamPos.visible and usePlayerWarpCamMarker \
				else PlayerFinder.player.position
		PlayerFinder.player.hold_camera_at(pos, holdX, holdY)

func _on_area_exited(area: Area2D):
	if area.name == 'PlayerEventCollider' and not disabled and not PlayerFinder.player.inCutscene and not SceneLoader.cutscenePlayer.playing:
		#print('release camera!')
		PlayerFinder.player.snap_camera_back_to_player()
