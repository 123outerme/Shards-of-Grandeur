extends CombatantAiLayer
class_name RandomCombatantAiLayer

## the weight is effectively random in the range [0.5, 1.5]
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState, allCombatantNodes: Array[CombatantNode]) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState, allCombatantNodes)
	if baseWeight < 0:
		return -1
	return baseWeight * randf_range(0.5, 1.5)

func copy(copyStorage: bool = false) -> RandomCombatantAiLayer:
	return RandomCombatantAiLayer.new(weight, copy_sublayers(copyStorage))
