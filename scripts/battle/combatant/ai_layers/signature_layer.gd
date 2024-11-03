extends CombatantAiLayer
class_name CombatantAiSignatureLayer

## if the move is a signature move, weight it higher
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, battleState: BattleState) -> float:
	if super.weight_move_effect_on_target(user, move, effectType, orbs, target, battleState) < 0:
		return -1
	
	if user.combatant.stats.movepool.signatureMoves.has(move):
		return 1.25
	return 1
