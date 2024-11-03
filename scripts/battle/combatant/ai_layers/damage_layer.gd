extends CombatantAiLayer
class_name DamageCombatantAiLayer

## if true, flips the logic to actually weight healing instead of damage
@export var healLayer: bool = false

## the more damage a move will do against this target, the higher its weight is
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	var moveWeight: float = 1
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(orbs)
	
	var targetElementEffectiveness: float = target.combatant.get_element_effectiveness_multiplier(move.element)
	var percentElementBoost: float = user.combatant.statChanges.get_element_multiplier(move.element)
	
	var userBoostedStats: Stats = user.combatant.statChanges.apply(user.combatant.stats)
	var targetStats: Stats = target.combatant.statChanges.apply(target.combatant.stats)
	var attackStat: float = userBoostedStats.get_stat_for_dmg_category(move.category)
	
	var calcdDamage: float = BattleCommand.damage_formula(moveEffect.power, attackStat, targetStats.resistance, user.combatant.stats.level, target.combatant.stats.level, targetElementEffectiveness * percentElementBoost)
	if healLayer:
		calcdDamage *= -1
	
	var highestOtherMoveDmg: int = 0
	var highestOtherMove: Move = null
	for otherMove: Move in user.combatant.stats.moves:
		if otherMove == move:
			continue
		var otherMoveEffect: MoveEffect = otherMove.get_effect_of_type(effectType)
		if effectType == Move.MoveEffectType.SURGE:
			otherMoveEffect = otherMoveEffect.apply_surge_changes(orbs)
		var otherAttackStat: float = userBoostedStats.get_stat_for_dmg_category(otherMove.category)
		var otherTargetElEff: float = target.combatant.get_element_effectiveness_multiplier(otherMove.element)
		var otherElementBoost: float = user.combatant.statChanges.get_element_multiplier(otherMove.element)
		var otherDmg: int = BattleCommand.damage_formula(otherMoveEffect.power, otherAttackStat, targetStats.resistance, user.combatant.stats.level, target.combatant.stats.level, otherTargetElEff * otherElementBoost)
		if healLayer:
			otherDmg *= -1
		if highestOtherMove == null or otherDmg > highestOtherMoveDmg:
			highestOtherMove = otherMove
			highestOtherMoveDmg = otherDmg
	
	if highestOtherMoveDmg > 0:
		moveWeight *= abs(calcdDamage / highestOtherMoveDmg)
	else:
		moveWeight *= 1.25 # no other moves did any damage
	#print('DEBUG damage layer: ', calcdDamage, ' / ', highestOtherMoveDmg, ' / ', moveWeight)
	
	# if not heal layer and targeting an ally, or is heal layer and targeting an enemy; inverse weighting (higher is now worse)
	if (user.role == target.role) != healLayer and moveWeight > 0:
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight
