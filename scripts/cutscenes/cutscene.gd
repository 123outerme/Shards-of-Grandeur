extends Resource
class_name Cutscene

@export var cutsceneFrames: Array[CutsceneFrame] = []
@export var saveName: String = ''
@export var storyRequirements: StoryRequirements = null
@export var unlockCameraHoldAfter: bool = true
var totalTime: float = 0

func _init(
	i_frames: Array[CutsceneFrame] = [],
	i_saveName = '',
	i_storyRequirements = null,
	i_unlockCameraAfter = true,
):
	cutsceneFrames = i_frames
	saveName = i_saveName
	storyRequirements = i_storyRequirements
	unlockCameraHoldAfter = i_unlockCameraAfter

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
