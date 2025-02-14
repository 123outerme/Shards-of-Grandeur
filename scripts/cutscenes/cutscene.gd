@tool
extends Resource
class_name Cutscene

## the keyframes that make up this cutscene
@export var cutsceneFrames: Array[CutsceneFrame] = []

## if not empty, the save name to set as seen the first time this cutscene plays
@export var saveName: String = ''

## the requirements to trigger this cutscene
@export var storyRequirements: StoryRequirements = null

## if false and the camera is being held, the camera will continue to be held when normal gameplay resumes. Only meant for instances where the camera is held and a warpzone is hit offscreen
@export var unlockCameraHoldAfter: bool = true

## set these actors' `invisible` or `visible` properties to be visible before the first frame processes
@export var activateActorsBefore: Array[String] = []

## set these actors' `invisible` or `visible` properties to not be visible after the last frame processes
@export var deactivateActorsAfter: Array[String] = []

## gives this quest at the end of the cutscene, if defined and the quest hasn't already been obtained
@export var givesQuest: Quest = null

## starts this static encounter if possible at the end of the cutscene
@export var staticEncounter: StaticEncounter = null

## if true, this cutscene won't play again until the map is reloaded (assuming `storyRequirements` still pass)
@export var tempDisabledAfter: bool = false

## misc. notes for editor usage only
@export_multiline var notes: String = ''

var totalTime: float = 0

func _init(
	i_frames: Array[CutsceneFrame] = [],
	i_saveName: String = '',
	i_storyRequirements: StoryRequirements = null,
	i_unlockCameraAfter: bool = true,
	i_activateActorsBefore: Array[String] = [],
	i_deactivateActorsAfter: Array[String] = [],
	i_givesQuest: Quest = null,
	i_staticEncounter: StaticEncounter = null,
	i_tempDisabledAfter: bool = false,
	i_notes: String = '',
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
	notes = i_notes

func get_keyframe_at_time(time: float, prevFrame: CutsceneFrame = null) -> CutsceneFrame:
	var accumulator: float = 0
	var foundPrevFrame: bool = false
	for frame in cutsceneFrames:
		if (time >= accumulator and time < accumulator + frame.frameLength) or foundPrevFrame:
			return frame
		if prevFrame == frame:
			foundPrevFrame = true
		accumulator += frame.frameLength
	
	# if a text box is blocking the cutscene from ending, this is the keyframe being played currently
	if prevFrame != null and foundPrevFrame and time >= accumulator and prevFrame.endTextBoxPauses:
		return prevFrame
		
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
