extends Node2D

## When the current-turn combatant fully finishes its Move animation (including MoveSprites, combatant SpriteFrames, movement)
signal combatant_finished_moving

## When the current-turn combatant indicates its move animation has completed enough for its targets to play their taking-damage animations, this fires
signal combatants_play_hit

## When the current-turn combatant completes animating its SpriteFrames animation
signal combatant_finished_animating

@export var globalMarker: Marker2D = null

func _move_tween_done():
	combatant_finished_moving.emit()