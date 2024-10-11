@tool
extends Resource
class_name CutsceneFrame

enum CameraFade {
	NONE = 0,
	FADE_OUT = 1,
	FADE_IN = 2,
}

## time to play this cutscene for in seconds
@export var frameLength: float = 1

## editor-only usage; has no effect on the actual cutscene
@export_multiline var annotation: String = ''

## tweens to play for actors (tween time is `frameLength`)
@export var actorTweens: Array[ActorTween] = []

## sprite animations to play for actors (continues after frame ends)
@export var actorAnims: Array[ActorSpriteAnim] = []

## animation sets/"sprite states" to set actors onto (continues after frame ends)
@export var actorAnimSets: Array[ActorAnimSet] = []

## instructions for changing the facing direction of actors that support it
@export var actorFaceTargets: Array[ActorFaceTarget] = []

## dialogues to play when this frame ends
@export var dialogues: Array[CutsceneDialogue] = []

## SFX to play at the start of this frame
@export var playSfx: AudioStream = null

## pause until an already-open textbox is closed (does not count if dialogues were just opened this frame)
@export var endTextBoxPauses: bool = true

## if true, shakes the camera for the entire frame's duration (if the player has camera shake enabled)
@export var shakeCamForDuration: bool = false

## if true, holds the camera at its current position until the end of the next frame that sets this false
@export var endHoldCamera: bool = false

## must enable endHoldCamera on the previous frame to use this. Defines camera panning
@export var cameraMovement: CutsceneCameraMovement = null

## if not set to `NONE`, will have the camera fade in/out at the end of this frame
@export var endFade: CameraFade = CameraFade.NONE

## for an `endFade` that's not `NONE`, determines the time the fade in/out takes
@export var endFadeLength: float = 0

## at the end of the frame, gives the player the defined item (if any)
@export var givesItem: Item = null

## if true, at the end of the frame, fully heals the player
@export var healsPlayer: bool = false

## if not an empty string, at the end of the frame, makes the NPCs with the specified follower ID follow the player in the overworld
@export var addsFollowerId: String = ''

## if not an empty string, at the end of the frame, stops the NPCs with the specified follower ID following the player in the overworld
@export var removesFollowerId: String = ''

## if true, at the end of the frame, starts the tutorial to teach how to learn moves from Shards
@export var endStartsShardLearnTutorial: bool = false

## if true, the text was already triggered for this frame
var endTextTriggered: bool = false

func _init(
	i_frameLength = 1,
	i_annotation: String = '',
	i_actorTweens: Array[ActorTween] = [],
	i_actorAnims: Array[ActorSpriteAnim] = [],
	i_actorAnimSets: Array[ActorAnimSet] = [],
	i_actorFaceTargets: Array[ActorFaceTarget] = [],
	i_dialogues: Array[CutsceneDialogue] = [],
	i_playSfx = null,
	i_endTextPauses = true,
	i_shakeCamForDuration = false,
	i_endHoldCam = false,
	i_cameraMovement = null,
	i_endFade = CameraFade.NONE,
	i_givesItem = null,
	i_healsPlayer = false,
	i_endStartsShardLearnTutorial = false,
):
	frameLength = i_frameLength
	annotation = i_annotation
	actorTweens = i_actorTweens
	actorAnims = i_actorAnims
	actorAnimSets = i_actorAnimSets
	actorFaceTargets = i_actorFaceTargets
	dialogues = i_dialogues
	playSfx = i_playSfx
	endTextBoxPauses = i_endTextPauses
	shakeCamForDuration = i_shakeCamForDuration
	endHoldCamera = i_endHoldCam
	cameraMovement = i_cameraMovement
	endFade = i_endFade
	givesItem = i_givesItem
	healsPlayer = i_healsPlayer
	endStartsShardLearnTutorial = i_endStartsShardLearnTutorial
	endTextTriggered = false
	
func get_text_was_triggered() -> bool:
	return endTextTriggered

func set_text_was_triggered(triggered: bool = true):
	endTextTriggered = triggered

func reset_internals():
	set_text_was_triggered(false)
