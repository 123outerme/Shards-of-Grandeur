extends CombatantAiLayer
class_name DamageCombatantAiLayer

## if true, flips the logic to actually weight healing instead of damage
@export var healLayer: bool = false

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[CombatantAiLayer] = [],
	i_healLayer: bool = false,
) -> void:
	super(i_weight, i_subLayers)
	healLayer = i_healLayer

## the more damage a move will do against this target, the higher its weight is
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	var moveWeight: float = 1
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(absi(orbs))
	
	var targetElementEffectiveness: float = target.combatant.get_element_effectiveness_multiplier(move.element)
	var percentElementBoost: float = user.combatant.statChanges.get_element_multiplier(move.element)
	
	var userBoostedStats: Stats = user.combatant.statChanges.apply(user.combatant.stats)
	var targetStats: Stats = target.combatant.statChanges.apply(target.combatant.stats)
	var attackStat: float = userBoostedStats.get_stat_for_dmg_category(move.category)
	
	var calcdDamage: float = BattleCommand.damage_formula(moveEffect.power, attackStat, targetStats.resistance, user.combatant.stats.level, target.combatant.stats.level, targetElementEffectiveness * percentElementBoost)
	if healLayer:
		calcdDamage *= -1
	
	var runeDmgs: Array[int] = []
	var moveTriggersRuneIdxs: Array[int] = []
	for idx in range(len(target.combatant.runes)):
		var rune: Rune = target.combatant.runes[idx]
		if rune.caster != null:
			var casterStats: Stats = rune.caster.statChanges.apply(rune.caster.stats)
			var runeAtkStat: int = casterStats.get_stat_for_dmg_category(rune.category)
			var runeElEffectiveness: float = target.combatant.get_element_effectiveness_multiplier(rune.element)
			var runeElementBoost: float = rune.caster.statChanges.get_element_multiplier(rune.element)
			runeDmgs.append(BattleCommand.damage_formula(rune.power, runeAtkStat, targetStats.resistance, rune.caster.stats.level, target.combatant.stats.level, runeElEffectiveness * runeElementBoost))
	
	for rune: Rune in CombatantAiLayer.get_runes_on_combatant_move_triggers(user, move, effectType, orbs, target, battleState, target.combatant.runes):
		moveTriggersRuneIdxs.append(target.combatant.runes.find(rune))
	
	if len(runeDmgs) > 0:
		print('Damages for runes ', runeDmgs, ' / and idxs we can trigger: ', moveTriggersRuneIdxs, ' / with move ', move.moveName)
	
	for idx: int in range(len(runeDmgs)):
		if healLayer:
			runeDmgs[idx] *= -1
		if idx in moveTriggersRuneIdxs:
			calcdDamage += runeDmgs[idx]
	
	
	
	var highestOtherMoveDmg: int = 0
	var highestOtherMove: Move = null
	var otherOrbs: int = orbs
	#var highestOtherLifesteal: float = 0
	for otherMove: Move in user.combatant.stats.moves:
		if otherMove == move:
			continue
		# if this surge move cannot be surged with the preferred number of orbs:
		if effectType == Move.MoveEffectType.SURGE and otherMove.surgeEffect.orbChange < orbs:
			# if the user can surge this move with more orbs, test with that
			if user.combatant.orbs >= absi(otherMove.surgeEffect.orbChange):
				otherOrbs = otherMove.surgeEffect.orbChange
			else:
				continue # otherwise, skip this move; it can't use it
		
		var otherMoveTriggersRuneIdxs: Array[int] = []
		for rune: Rune in CombatantAiLayer.get_runes_on_combatant_move_triggers(user, otherMove, effectType, otherOrbs, target, battleState, target.combatant.runes):
			otherMoveTriggersRuneIdxs.append(target.combatant.runes.find(rune))
		var otherMoveEffect: MoveEffect = otherMove.get_effect_of_type(effectType)
		if effectType == Move.MoveEffectType.SURGE:
			otherMoveEffect = otherMoveEffect.apply_surge_changes(absi(otherOrbs))
		var otherAttackStat: float = userBoostedStats.get_stat_for_dmg_category(otherMove.category)
		var otherTargetElEff: float = target.combatant.get_element_effectiveness_multiplier(otherMove.element)
		var otherElementBoost: float = user.combatant.statChanges.get_element_multiplier(otherMove.element)
		var otherDmg: int = BattleCommand.damage_formula(otherMoveEffect.power, otherAttackStat, targetStats.resistance, user.combatant.stats.level, target.combatant.stats.level, otherTargetElEff * otherElementBoost)
		if healLayer:
			otherDmg *= -1
		
		for idx in range(len(target.combatant.runes)):
			if idx in otherMoveTriggersRuneIdxs:
				otherDmg += runeDmgs[idx]
		
		if highestOtherMove == null or otherDmg > highestOtherMoveDmg:
			highestOtherMove = otherMove
			highestOtherMoveDmg = otherDmg
			#highestOtherLifesteal = otherMoveEffect.lifesteal
	
	if abs(calcdDamage) > 0:
		if highestOtherMoveDmg > 0:
			moveWeight *= abs(calcdDamage / highestOtherMoveDmg)
			if moveEffect.lifesteal > 0:
				moveWeight *= 1 + moveEffect.lifesteal
		else:
			moveWeight *= 1.25 # no other moves did any damage
		# if not heal layer and targeting an ally, or is heal layer and targeting an enemy; inverse weighting (higher is now worse)
		if (user.role == target.role) != healLayer and moveWeight > 0:
			moveWeight = 1 / moveWeight
	elif int(calcdDamage) == 0:
		moveWeight = 1
	
	#print('DEBUG damage layer: ', calcdDamage, ' / ', highestOtherMoveDmg, ' / ', moveWeight)
	
	return baseWeight * moveWeight

func copy(copyStorage: bool = false) -> DamageCombatantAiLayer:
	return DamageCombatantAiLayer.new(weight, copy_sublayers(copyStorage), healLayer)
