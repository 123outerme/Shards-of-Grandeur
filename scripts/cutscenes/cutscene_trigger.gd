extends Area2D
class_name CutsceneTrigger

@export var cutscenes: Array[Cutscene] = []
@export var disabled: bool = false
@export var cutscenePlayer: CutscenePlayer = null

func _ready():
	if len(cutscenes) == 0:
		queue_free() # delete self if no cutscenes

func cutscene_finished(cutscene: Cutscene):
	var idx = cutscenes.find(cutscene)
	if idx != -1:
		cutscene.reset_internals()
	# re-check validity of all cutscenes
	var allInvalid: bool = true
	for scene in cutscenes:
		if scene.storyRequirements != null and cutscene.storyRequirements.is_valid():
			allInvalid = false
	disabled = allInvalid

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and not disabled and not cutscenePlayer.playing:
		for cutscene in cutscenes:
			if cutscene != null and \
				(cutscene.storyRequirements == null or cutscene.storyRequirements.is_valid()):
				cutscenePlayer.playingFromTrigger = self
				cutscenePlayer.start_cutscene(cutscene)
				break
