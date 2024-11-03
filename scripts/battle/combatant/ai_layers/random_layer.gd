extends CombatantAiLayer
class_name CombatantAiRandomLayer

# TODO: maybe it's ok to make `target` a type of combatant?
## the weight is effectively random in the range [0.5, 1.5]
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	return baseWeight * randf_range(0.5, 1.5)
