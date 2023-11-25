extends Resource
class_name Cutscene

@export var cutsceneFrames: Array[CutsceneFrame] = []
@export var saveName: String = ''
@export var storyRequirements: StoryRequirements = null
@export var unlockCameraHoldAfter: bool = true
@export var deactivateActorsAfter: Array[String] = []
@export var givesQuest: Quest = null
var totalTime: float = 0

func _init(
	i_frames: Array[CutsceneFrame] = [],
	i_saveName = '',
	i_storyRequirements = null,
	i_unlockCameraAfter = true,
	i_deactivateActorsAfter: Array[String] = [],
	i_givesQuest = null,
):
	cutsceneFrames = i_frames
	saveName = i_saveName
	storyRequirements = i_storyRequirements
	unlockCameraHoldAfter = i_unlockCameraAfter
	deactivateActorsAfter = i_deactivateActorsAfter
	givesQuest = i_givesQuest

func get_keyframe_at_time(time: float) -> CutsceneFrame:
	var accumulator: float = 0
	for frame in cutsceneFrames:
		if time >= accumulator and time < accumulator + frame.frameLength:
			return frame
		accumulator += frame.frameLength
	return null

func calc_total_time():
	for frame in cutsceneFrames:
		totalTime += frame.frameLength

func reset_internals():
	for frame in cutsceneFrames:
		frame.reset_internals()
