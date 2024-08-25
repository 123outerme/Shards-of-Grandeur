extends Node2D

signal combatant_finished_moving
signal combatants_play_hit
signal combatant_finished_animating

@export var moveLearnAnimController: MoveLearnAnimationController = null
@export var globalMarker: Marker2D = null

func _move_tween_done():
	moveLearnAnimController.move_tween_done()
