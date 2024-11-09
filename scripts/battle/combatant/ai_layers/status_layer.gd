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
		moveEffect = moveEffect.apply_surge_changes(absi(orbs))
	
	var statusEffect: StatusEffect = moveEffect.statusEffect
	var selfGetsStatus: bool = moveEffect.selfGetsStatus
	var statusChance: float = min(1, max(0, moveEffect.statusChance))
	
	for rune: Rune in CombatantAiLayer.get_runes_on_combatant_move_triggers(user, move, effectType, orbs, target, battleState, target.combatant.runes):
		if rune.statusEffect != null and (statusEffect == null or rune.statusEffect.overwritesOtherStatuses):
			statusEffect = rune.statusEffect
			selfGetsStatus = false
			statusChance = 1.0
	
	
	if statusEffect == null or statusEffect.potency == StatusEffect.Potency.NONE:
		return 1
	
	if selfGetsStatus:
		target = user
	
	if not statusEffect.overwritesOtherStatuses and target.combatant.statusEffect != null:
			return 1
	
	if statusEffect.potency == StatusEffect.Potency.WEAK:
		moveWeight += 0.15
	if statusEffect.potency == StatusEffect.Potency.STRONG:
		moveWeight += 0.3
	if statusEffect.potency == StatusEffect.Potency.OVERWHELMING:
		moveWeight += 0.45
	
	moveWeight *= min(1, statusChance) / AVERAGE_STATUS_CHANCE
	
	# if it's a positive status effect and the target is an enemy, or vice versa:
	if (user.role != target.role) == statusEffect.is_positive_status():
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight

func copy(copyStorage: bool = false)  -> StatusCombatantAiLayer:
	return StatusCombatantAiLayer.new(weight, copy_sublayers(copyStorage))
