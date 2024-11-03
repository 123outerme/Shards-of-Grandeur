extends CombatantAiLayer
class_name StatusCombatantAiLayer

const AVERAGE_STATUS_CHANCE: float = 0.65

## the better the status is, the higher the weight
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	var moveWeight: float = 1
	
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(orbs)
	
	if moveEffect.statusEffect == null or moveEffect.statusEffect.potency == StatusEffect.Potency.NONE:
		return 0
	
	if moveEffect.selfGetsStatus:
		target = user
	
	if not moveEffect.statusEffect.overwritesOtherStatuses and target.combatant.statusEffect != null:
			return 0
	
	if moveEffect.statusEffect.potency == StatusEffect.Potency.STRONG:
		moveWeight += 0.15
	if moveEffect.statusEffect.potency == StatusEffect.Potency.OVERWHELMING:
		moveWeight += 0.3
	
	moveWeight *= min(1, moveEffect.statusChance) / AVERAGE_STATUS_CHANCE
	
	# if it's a positive status effect and the target is an enemy, or vice versa:
	if (user.role != target.role) == moveEffect.statusEffect.is_positive_status():
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight
