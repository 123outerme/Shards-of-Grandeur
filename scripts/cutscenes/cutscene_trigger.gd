extends Area2D
class_name CutsceneTrigger

@export var cutscene: Cutscene
@export var disabled: bool = false
@export var cutscenePlayer: CutscenePlayer = null

func _ready():
	if cutscene == null or not cutscene.storyRequirements.is_valid():
		queue_free() # delete self if player has seen cutscene

func cutscene_finished():
	cutscene.reset_internals()
	disabled = not cutscene.storyRequirements.is_valid() # re-check validity

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and not disabled and not cutscenePlayer.playing:
		cutscenePlayer.playingFromTrigger = self
		cutscenePlayer.start_cutscene(cutscene)
