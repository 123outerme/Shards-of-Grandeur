extends CombatantAiLayer
class_name CombatantAiOrderedLayer

@export var moveList: Array[Move] = []
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
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, battleState: BattleState) -> float:
	if super.weight_move_effect_on_target(user, move, effectType, orbs, target, battleState) < 0:
		return -1
	
	if len(moveList) == 0:
		return 1
	
	if move == moveList[moveIdx]:
		return 1.5
	return 0.5

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	if move == moveList[moveIdx]:
		moveIdx = (moveIdx + 1) % len(moveList)
