extends CombatantAiLayer
class_name MoveOrderedCombatantAiLayer

## the list of specific moves to attempt to use in sequence
@export var moveList: Array[Move] = []

## if true, continue to use these moves forever, otherwise stop weighting these moves after the first iteration
@export var loop: bool = true

@export_storage var moveIdx: int = 0

func _init(
	i_weight: float = 1.0,
	i_moveList: Array[Move] = [],
	i_moveIdx: int = 0,
) -> void:
	super(weight)
	moveList = i_moveList.duplicate(false)
	moveIdx = i_moveIdx

# TODO: can I use Combatant/CombatantNode here instead of Variant?
## returns 1.5 if the move is the next move in the order, otherwise 0.5
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	if len(moveList) == 0 or moveIdx >= len(moveList):
		return 1
	
	if move == moveList[moveIdx]:
		return baseWeight * 1.4
	return baseWeight * 0.6

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	if move == moveList[moveIdx]:
		moveIdx += 1
		if loop:
			moveIdx = moveIdx % len(moveList)
