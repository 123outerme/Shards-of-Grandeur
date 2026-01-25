extends Area2D
class_name CutsceneTrigger

@export var cutscenes: Array[Cutscene] = []
@export var disabled: bool = false

var playerInTriggerBounds: bool = false

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
		if scene.storyRequirements == null or scene.storyRequirements.is_valid():
			allInvalid = false
	disabled = allInvalid

func _on_area_entered(area):
	if area.name == "PlayerEventCollider":
		playerInTriggerBounds = true
		if not disabled:
			if not SceneLoader.cutscenePlayer.playing or SceneLoader.cutscenePlayer.completeAfterFadeIn:
				if SceneLoader.cutscenePlayer.completeAfterFadeIn:
					SceneLoader.cutscenePlayer.complete_cutscene()
				start_cutscene()
			else:
				await SceneLoader.cutscenePlayer.cutscene_completed
				# when the cutscene finishes, if the player is still within this trigger's bounds and another cutscene is not already playing: play one from this trigger
				if playerInTriggerBounds and not SceneLoader.cutscenePlayer.playing:
					start_cutscene()

func _on_area_exited(area: Area2D) -> void:
	if area.name == "PlayerEventCollider":
		playerInTriggerBounds = false

func start_cutscene() -> void:
	for cutscene in cutscenes:
		if cutscene != null and \
				(cutscene.storyRequirements == null or cutscene.storyRequirements.is_valid()) and \
				not PlayerResources.playerInfo.is_cutscene_temp_disabled(cutscene.saveName):
			SceneLoader.cutscenePlayer.playingFromTrigger = self
			SceneLoader.cutscenePlayer.start_cutscene(cutscene)
			break
