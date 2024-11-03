extends CombatantAiLayer
class_name CombatantAiDebuffLayer

enum DebuffStrategy {
	DEBUFF_WEAKEST = 0, ## attempt to debuff the weakest stat on the weakest available target
	DEBUFF_STRONGEST = 1, ## attempt to debuff the strongest stat on the strongest available target
}

@export var debuffStrategy: DebuffStrategy = DebuffStrategy.DEBUFF_STRONGEST

## the stronger the debuff is based on the debuff strategy, the higher the weight
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, battleState: BattleState) -> float:
	if super.weight_move_effect_on_target(user, move, effectType, orbs, target, battleState) < 0:
		return -1
	
	var moveWeight: float = 1
	
	# TODO
	
	if user.role == target.role:
		moveWeight = 1 / moveWeight
	
	return moveWeight
