extends Node2D
class_name MockBattleController

## ## When the current-turn combatant is moving back to its "rest" position (initial battle pos) after moving towards some other location
signal combatant_returning_to_rest(combatant: CombatantNode)

## When the current-turn combatant fully finishes its Move animation (including MoveSprites, combatant SpriteFrames, movement)
signal combatant_finished_moving(combatant: CombatantNode)

## When the current-turn combatant indicates its move animation has completed enough for its targets to play their taking-damage animations, this fires
signal combatants_play_hit(combatant: CombatantNode)

## When the current-turn combatant completes animating its SpriteFrames animation
signal combatant_finished_animating(combatant: CombatantNode)

signal battlefield_shade_finished_fading

@export var globalMarker: Marker2D = null
@export var battlefieldShade: BattlefieldShade = null

var playerCombatantNode: CombatantNode = null
var combatantNodes: Array[CombatantNode] = []

## combatant will always be above shade
func set_combatant_above_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = 2

## Combatant will always be below shade
func set_combatant_below_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = 0

## Default combatant z-index. Sets combatant above the shade if the shade is at its "normal" height, if shade is raised then the combatant will be below
func set_combatant_between_shade(combatantNode: CombatantNode) -> void:
	combatantNode.z_index = 1

func reset_all_combatants_shade_z_indices() -> void:
	for combatantNode: CombatantNode in combatantNodes:
		set_combatant_between_shade(combatantNode)
