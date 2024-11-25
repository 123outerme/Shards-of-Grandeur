extends Area2D
class_name CameraHoldZone

## if true, will freeze camera movement in the X-direction (good for horizontal warp zones)
@export var holdX: bool = true

## if true, will freeze camera movement in the Y-direction (good for vertical warp zones)
@export var holdY: bool = true

## if true, will not hold the camera when the player enters
@export var disabled: bool = false

## if true, will set the player's camera to the `PlayerWarpCamPos` marker on entering the zone, otherwise will hold on the camera's last position before entering
@export var usePlayerWarpCamMarker: bool = false

@onready var playerWarpCamPos: Marker2D = get_node('PlayerWarpCamPos')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_area_entered(area: Area2D):
	if area.name == 'PlayerEventCollider' and not disabled and \
			not PlayerFinder.player.inCutscene and not SceneLoader.cutscenePlayer.playing and \
			(not SceneLoader.mapLoader.loading or (playerWarpCamPos.visible and usePlayerWarpCamMarker)):
			
		#print('hold camera!')
		var pos = (position + playerWarpCamPos.position) \
				if SceneLoader.mapLoader.loading and playerWarpCamPos.visible and usePlayerWarpCamMarker \
				else PlayerFinder.player.position
		PlayerFinder.player.hold_camera_at(pos, holdX, holdY)

func _on_area_exited(area: Area2D):
	if area.name == 'PlayerEventCollider' and not disabled and not PlayerFinder.player.inCutscene and not SceneLoader.cutscenePlayer.playing:
		#print('release camera!')
		PlayerFinder.player.snap_camera_back_to_player()
