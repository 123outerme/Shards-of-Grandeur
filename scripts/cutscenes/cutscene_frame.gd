extends Resource
class_name CutsceneFrame

enum CameraFade {
	NONE = 0,
	FADE_OUT = 1,
	FADE_IN = 2,
}

@export var frameLength: float = 1
@export var actorTweens: Array[ActorTween] = []
@export var actorAnims: Array[ActorSpriteAnim] = []
@export var endTextBoxSpeaker: String = ''
@export_multiline var endTextBoxTexts: Array[String] = []
@export var endTextBoxPauses: bool = true
@export var endHoldCamera: bool = false
@export var endFade: CameraFade = CameraFade.NONE
@export var endFadeLength: float = 0
@export var givesItem: Item = null
var endTextTriggered: bool = false

func _init(
	i_frameLength = 1,
	i_actorTweens: Array[ActorTween] = [],
	i_actorAnims: Array[ActorSpriteAnim] = [],
	i_endTextSpeaker = '',
	i_endTexts: Array[String] = [],
	i_endTextPauses = true,
	i_endHoldCam = false,
	i_endFade = CameraFade.NONE,
	i_givesItem = null,
):
	frameLength = i_frameLength
	actorTweens = i_actorTweens
	actorAnims = i_actorAnims
	endTextBoxSpeaker = i_endTextSpeaker
	endTextBoxTexts = i_endTexts
	endTextBoxPauses = i_endTextPauses
	endHoldCamera = i_endHoldCam
	endFade = i_endFade
	givesItem = i_givesItem
	endTextTriggered = false
	
func get_text_was_triggered() -> bool:
	return endTextTriggered

func set_text_was_triggered(triggered: bool = true):
	endTextTriggered = triggered

func reset_internals():
	set_text_was_triggered(false)
