extends CombatantAiLayer
class_name RuneCombatantAiLayer

## the extra multiplier for the rune effect weight if that target's rune can be triggered with this move. Other AI layers care about their specific results they can achieve through activating Runes, as well
@export var triggerWeight: float = 1.25

## the multiplier for the rune effect weight of the rune that this move sets
@export var setWeight: float = 1.15

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[CombatantAiLayer] = [],
	i_triggerWeight: float = 1.25,
	i_setWeight: float = 1.15,
) -> void:
	super(i_weight, i_subLayers)
	triggerWeight = i_triggerWeight
	setWeight = i_setWeight

## if the move will trigger a rune or set a rune, weight it based on the power of the rune(s) and if it's triggering or being cast
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(absi(orbs))
	
	var finalSetWeight: float = setWeight * get_rune_weight_on_target(user, moveEffect.rune, target, targets, battleState)
	
	#if moveEffect.rune != null:
	#	print('DEBUG:: move effect rune is not null for ', move.moveName)
	
	var finalTriggerWeight: float = triggerWeight
	
	var targetRunesTriggered: Array[Rune] = CombatantAiLayer.get_runes_on_combatant_move_triggers(user, move, effectType, orbs, target, battleState, target.combatant.runes)
	var userRunesTriggered: Array[Rune] = targetRunesTriggered if user == target else CombatantAiLayer.get_runes_on_combatant_move_triggers(user, move, effectType, orbs, target, battleState, user.combatant.runes)
	
	for rune: Rune in targetRunesTriggered:
		finalTriggerWeight *= get_rune_weight_on_target(user, rune, target, targets, battleState)
	
	for rune: Rune in userRunesTriggered:
		if not (rune in targetRunesTriggered):
			finalTriggerWeight *= get_rune_weight_on_target(user, rune, user, targets, battleState)
	
	#print('DEBUG::: final rune weights ', finalSetWeight, ' / ', finalTriggerWeight, ' / for move ', move.moveName)
	
	return baseWeight * finalSetWeight * finalTriggerWeight

func get_rune_weight_on_target(user: CombatantNode, rune: Rune, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	if rune == null:
		return 1
	
	var runeWeight: float = 1
	
	var caster: Combatant = rune.caster if rune.caster != null else user.combatant
	
	var orbDiff: int = max(0, min(Combatant.MAX_ORBS, rune.orbChange + caster.orbs)) - caster.orbs
	runeWeight *= 1 + (orbDiff * .05) # +5% weight for each orb that will actually be gained

	var powerRatio: float = rune.power / 100.0
	if target.role == CombatantNode.Role.ALLY:
		powerRatio *= -1
	
	runeWeight *= 1 + powerRatio
	runeWeight *= 1 + rune.lifesteal
	
	var statChangeWeight: float = 1
	if rune.statChanges != null:
		var targetStats: Stats = target.combatant.statChanges.apply(target.combatant.stats)
		var highestElementMultiplier: float = 1.0
		for elMultiplier: ElementMultiplier in target.combatant.statChanges.elementMultipliers:
			highestElementMultiplier = max(elMultiplier.multiplier, highestElementMultiplier)
		
		var stackedStatChanges: StatChanges = target.combatant.statChanges.copy()
		stackedStatChanges.stack(rune.statChanges)
		var stackedTargetStats: Stats = stackedStatChanges.apply(target.combatant.stats)
		var highestStackedElementMultiplier: float = 1.0
		for elMultiplier: ElementMultiplier in stackedStatChanges.elementMultipliers:
			highestStackedElementMultiplier = max(elMultiplier.multiplier, highestStackedElementMultiplier)
		
		statChangeWeight = targetStats.get_stat_total_including_dmg_boosts(highestElementMultiplier) / stackedTargetStats.get_stat_total_including_dmg_boosts(highestStackedElementMultiplier)
		if target.role == CombatantNode.Role.ALLY:
			statChangeWeight = 1.0 / statChangeWeight
		runeWeight *= statChangeWeight
	
	
	var statusWeight: float = 1
	if rune.statusEffect != null:
		var willApplyStatus: bool = false
		if target.combatant.statusEffect == null or rune.statusEffect.overwritesOtherStatuses:
			willApplyStatus = true
		if willApplyStatus:
			if rune.statusEffect.potency == StatusEffect.Potency.WEAK:
				statusWeight += 0.15
			if rune.statusEffect.potency == StatusEffect.Potency.STRONG:
				statusWeight += 0.3
			if rune.statusEffect.potency == StatusEffect.Potency.OVERWHELMING:
				statusWeight += 0.45
			if (user.role != target.role) == rune.statusEffect.is_positive_status():
				statusWeight = 1.0 / statusWeight
			runeWeight *= statusWeight
	
	#print('rune weights: ', powerRatio, ' / ', 1 + (orbDiff * .05), ' / ', rune.lifesteal, ' / ', statChangeWeight, ' / ', statusWeight, ' / final: ', runeWeight)
	
	return runeWeight

func copy(copyStorage: bool = false)  -> RuneCombatantAiLayer:
	return RuneCombatantAiLayer.new(weight, copy_sublayers(copyStorage))
