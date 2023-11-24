extends Area2D
class_name CutsceneTrigger

@export var cutscene: Cutscene
@export var disabled: bool = false
@export var cutscenePlayer: CutscenePlayer = null

func _ready():
	if cutscene == null or PlayerResources.playerInfo.has_seen_cutscene(cutscene.saveName):
		queue_free() # delete self if player has seen cutscene

func cutscene_finished():
	queue_free() # delete self

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and not disabled and not cutscenePlayer.playing:
		cutscenePlayer.playingFromTrigger = self
		cutscenePlayer.start_cutscene(cutscene)
