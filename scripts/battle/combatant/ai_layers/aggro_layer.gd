extends CombatantAiLayer
class_name AggroCombatantAiLayer

enum AggroStrategy {
	HIGHEST_HP = 0, ## the higher the current HP, the stronger the targeting
	LOWEST_HP = 1, ## the lower the current HP, the stronger the targeting
	MOST_ORBS = 2, ## the higher the amount of orbs, the stronger the targeting
	HIGHEST_STATS = 3, ## the higher the stats, the stronger the targeting
}

@export var aggroStrategy: AggroStrategy = AggroStrategy.HIGHEST_HP

## weights the move based on what strategy this layer uses for prioritizing targets
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	if len(targets) == 1:
		return 1
	
	var targetScore: float = 1
	var otherScore: float = 1
	match aggroStrategy:
		AggroStrategy.HIGHEST_HP, AggroStrategy.LOWEST_HP:
			targetScore = target.combatant.currentHp
		AggroStrategy.MOST_ORBS:
			targetScore = target.combatant.orbs + 1 # prevent divide by 0
		AggroStrategy.HIGHEST_STATS:
			var targetStats: Stats = target.combatant.statChanges.apply(target.combatant.stats)
			var highestElementBoost: float = 1.0
			for elementBoost: ElementMultiplier in target.combatant.statChanges.elementMultipliers:
				highestElementBoost = max(highestElementBoost, elementBoost.multiplier)
			targetScore = targetStats.get_stat_total_including_dmg_boosts(highestElementBoost)
	
	for combatantNode: CombatantNode in targets:
		if combatantNode == target:
			continue
		var score: float = 1
		match aggroStrategy:
			AggroStrategy.HIGHEST_HP, AggroStrategy.LOWEST_HP:
				score = combatantNode.combatant.currentHp
			AggroStrategy.MOST_ORBS:
				score = combatantNode.combatant.orbs + 1 # prevent divide by 0
			AggroStrategy.HIGHEST_STATS:
				var otherStats: Stats = combatantNode.combatant.statChanges.apply(combatantNode.combatant.stats)
				var highestElementBoost: float = 1.0
				for elementBoost: ElementMultiplier in combatantNode.combatant.statChanges.elementMultipliers:
					highestElementBoost = max(highestElementBoost, elementBoost.multiplier)
				targetScore = otherStats.get_stat_total_including_dmg_boosts(highestElementBoost)
		otherScore = max(otherScore, score)
	#print('DEBUG aggro layer: ', otherScore, ' / ', targetScore)
	if aggroStrategy == AggroStrategy.LOWEST_HP:
		return baseWeight * (otherScore / targetScore)
	return baseWeight * (targetScore / otherScore)
