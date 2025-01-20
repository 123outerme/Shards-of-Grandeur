extends CombatantAiLayer
class_name StatusCombatantAiLayer

const AVERAGE_STATUS_CHANCE: float = 0.65

## the better the status is, the higher the weight
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState, allCombatantNodes: Array[CombatantNode]) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState, allCombatantNodes)
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
	
	if target.combatant.statusEffect != null and not statusEffect.overwritesOtherStatuses:
		return 0.6 # it CAN status, but not this target, so don't prefer it
	
	var potencyWeight: float = 0
	if statusEffect.potency == StatusEffect.Potency.WEAK:
		potencyWeight = 0.15
		moveWeight += potencyWeight
	if statusEffect.potency == StatusEffect.Potency.STRONG:
		potencyWeight = 0.3
		moveWeight += potencyWeight
	if statusEffect.potency == StatusEffect.Potency.OVERWHELMING:
		potencyWeight = 0.45
		moveWeight += potencyWeight
	
	if target.combatant.statusEffect != null and statusEffect.overwritesOtherStatuses:
		if target.combatant.statusEffect.is_positive_status() != statusEffect.is_positive_status():
			# if the statuses swap from bad to good or vice versa, then this will be a positive change
			moveWeight += 0.1
		else:
			# if the statuses remain bad or remain good, then it depends on how much the potency changes
			# decrease the weight by the same amount as was added by potency and then some, but reduced by how much more potent this status is compared to the existing status
			moveWeight -= 0.2 + potencyWeight - (statusEffect.potency - target.combatant.statusEffect.potency) * 0.1
	
	moveWeight *= min(1, statusChance) / AVERAGE_STATUS_CHANCE
	
	# if it's a positive status effect and the target is an enemy, or vice versa:
	if (user.role != target.role) == statusEffect.is_positive_status():
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight

func copy(copyStorage: bool = false)  -> StatusCombatantAiLayer:
	return StatusCombatantAiLayer.new(weight, copy_sublayers(copyStorage))
