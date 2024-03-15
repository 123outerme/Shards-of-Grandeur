extends Area2D
class_name CutsceneTrigger

@export var cutscenes: Array[Cutscene] = []
@export var disabled: bool = false

func _ready():
	if len(cutscenes) == 0:
		queue_free() # delete self if no cutscenes

func cutscene_finished(cutscene: Cutscene):
	cutscene.reset_internals()
	if cutscene.tempDisabledAfter:
		PlayerResources.playerInfo.set_cutscene_temp_disabled(cutscene.saveName)
	# re-check validity of all cutscenes
	var allInvalid: bool = true
	for scene in cutscenes:
		if scene.storyRequirements != null and scene.storyRequirements.is_valid():
			allInvalid = false
	disabled = allInvalid

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and not disabled:
		if not SceneLoader.cutscenePlayer.playing or SceneLoader.cutscenePlayer.completeAfterFadeIn:
			if SceneLoader.cutscenePlayer.completeAfterFadeIn:
				SceneLoader.cutscenePlayer.complete_cutscene()
			for cutscene in cutscenes:
				if cutscene != null and \
						(cutscene.storyRequirements == null or cutscene.storyRequirements.is_valid()) and \
						not PlayerResources.playerInfo.is_cutscene_temp_disabled(cutscene.saveName):
					SceneLoader.cutscenePlayer.playingFromTrigger = self
					SceneLoader.cutscenePlayer.start_cutscene(cutscene)
					break
