extends CombatantAiLayer
class_name CombatantAiBuffLayer

enum BuffStrategy {
	BUFF_WEAKEST = 0, ## attempt to buff the weakest stat on the weakest available target
	BUFF_STRONGEST = 1, ## attempt to buff the strongest stat on the strongest available target
	BUFF_SELF_ONLY = 2, ## attempt to buff self only if possible
}

@export var buffStrategy: BuffStrategy = BuffStrategy.BUFF_STRONGEST

## the stronger the buff is based on the buff strategy, the higher the weight
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	var moveWeight: float = 1
	
	# TODO
	
	if user.role != target.role:
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight
