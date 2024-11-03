extends CombatantAiLayer
class_name SignatureCombatantAiLayer

## the multiplier for weighting to use when the move is a signature move
@export var signatureWeight: float = 1.25

## if the move is a signature move, weight it higher
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	if user.combatant.stats.movepool.signatureMoves.has(move):
		return baseWeight * signatureWeight
	return baseWeight
