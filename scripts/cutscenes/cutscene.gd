@tool
extends Resource
class_name Cutscene

@export var cutsceneFrames: Array[CutsceneFrame] = []
@export var saveName: String = ''
@export var storyRequirements: StoryRequirements = null
@export var unlockCameraHoldAfter: bool = true
@export var activateActorsBefore: Array[String] = []
@export var deactivateActorsAfter: Array[String] = []
@export var givesQuest: Quest = null
@export var staticEncounter: StaticEncounter = null
@export var tempDisabledAfter: bool = false
var totalTime: float = 0

func _init(
	i_frames: Array[CutsceneFrame] = [],
	i_saveName = '',
	i_storyRequirements = null,
	i_unlockCameraAfter = true,
	i_activateActorsBefore: Array[String] = [],
	i_deactivateActorsAfter: Array[String] = [],
	i_givesQuest = null,
	i_staticEncounter = null,
	i_tempDisabledAfter = false,
):
	cutsceneFrames = i_frames
	saveName = i_saveName
	storyRequirements = i_storyRequirements
	unlockCameraHoldAfter = i_unlockCameraAfter
	activateActorsBefore = i_activateActorsBefore
	deactivateActorsAfter = i_deactivateActorsAfter
	givesQuest = i_givesQuest
	staticEncounter = i_staticEncounter
	tempDisabledAfter = i_tempDisabledAfter

func get_keyframe_at_time(time: float, prevFrame: CutsceneFrame = null) -> CutsceneFrame:
	var accumulator: float = 0
	var foundPrevFrame: bool = false
	for frame in cutsceneFrames:
		if (time >= accumulator and time < accumulator + frame.frameLength) or foundPrevFrame:
			return frame
		if prevFrame == frame:
			foundPrevFrame = true
		accumulator += frame.frameLength
	return null

func get_current_frame_time(timer: float, prevFrame: CutsceneFrame = null) -> float:
	var accumulator: float = 0
	var foundPrevFrame: bool = false
	for frame in cutsceneFrames:
		if (timer >= accumulator and timer < accumulator + frame.frameLength) or foundPrevFrame:
			return timer - accumulator
		if prevFrame == frame:
			foundPrevFrame = true
		accumulator += frame.frameLength
	return accumulator

func get_index_for_frame(frame: CutsceneFrame) -> int:
	for idx in range(len(cutsceneFrames)):
		if frame == cutsceneFrames[idx]:
			return idx
	return -1

func calc_total_time():
	for frame in cutsceneFrames:
		totalTime += frame.frameLength

func reset_internals():
	for frame in cutsceneFrames:
		frame.reset_internals()
