@tool
extends Resource
class_name CutsceneFrame

enum CameraFade {
	NONE = 0,
	FADE_OUT = 1,
	FADE_IN = 2,
}

@export var frameLength: float = 1
@export_multiline var annotation: String = '' # editor-only usage; has no effect on the actual cutscene 
@export var actorTweens: Array[ActorTween] = []
@export var actorAnims: Array[ActorSpriteAnim] = []
@export var actorAnimSets: Array[ActorAnimSet] = []
@export var dialogues: Array[CutsceneDialogue] = []
@export var playSfx: AudioStream = null
@export var endTextBoxPauses: bool = true
@export var shakeCamForDuration: bool = false
@export var endHoldCamera: bool = false
@export var endFade: CameraFade = CameraFade.NONE
@export var endFadeLength: float = 0
@export var givesItem: Item = null
@export var endStartsShardLearnTutorial: bool = false
var endTextTriggered: bool = false

func _init(
	i_frameLength = 1,
	i_annotation: String = '',
	i_actorTweens: Array[ActorTween] = [],
	i_actorAnims: Array[ActorSpriteAnim] = [],
	i_actorAnimSets: Array[ActorAnimSet] = [],
	i_dialogues: Array[CutsceneDialogue] = [],
	i_playSfx = null,
	i_endTextPauses = true,
	i_shakeCamForDuration = false,
	i_endHoldCam = false,
	i_endFade = CameraFade.NONE,
	i_givesItem = null,
	i_endStartsShardLearnTutorial = false,
):
	frameLength = i_frameLength
	annotation = i_annotation
	actorTweens = i_actorTweens
	actorAnims = i_actorAnims
	actorAnimSets = i_actorAnimSets
	dialogues = i_dialogues
	playSfx = i_playSfx
	endTextBoxPauses = i_endTextPauses
	shakeCamForDuration = i_shakeCamForDuration
	endHoldCamera = i_endHoldCam
	endFade = i_endFade
	givesItem = i_givesItem
	endStartsShardLearnTutorial = i_endStartsShardLearnTutorial
	endTextTriggered = false
	
func get_text_was_triggered() -> bool:
	return endTextTriggered

func set_text_was_triggered(triggered: bool = true):
	endTextTriggered = triggered

func reset_internals():
	set_text_was_triggered(false)
