extends CombatantAiLayer
class_name DebuffCombatantAiLayer

enum DebuffStrategy {
	DEBUFF_WEAKEST = 0, ## attempt to debuff the weakest stat on the weakest available target
	DEBUFF_STRONGEST = 1, ## attempt to debuff the strongest stat on the strongest available target
}

@export var debuffStrategy: DebuffStrategy = DebuffStrategy.DEBUFF_STRONGEST

## the stronger the debuff is based on the debuff strategy, the higher the weight
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	var moveWeight: float = 1
	
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(orbs)
	
	var targetWeight: float = _calc_target_weight(user, move, effectType, orbs, target)
	var selfWeight: float = 1.0
	if user != target: # only if user is not the target (since we've already calc'd with target boosts)
		selfWeight = _calc_self_weight(user, move, effectType, orbs, target)
	moveWeight *= selfWeight * targetWeight
	
	if user.role != target.role:
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight

func _calc_target_weight(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode) -> float:
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(orbs)
	
	var statChanges: StatChanges = StatChanges.new()
	var weight: float = 1.0
	# if there are target stat changes: stack them
	if moveEffect.targetStatChanges != null:
		statChanges.stack(moveEffect.targetStatChanges)
	# calculate current stats, see how this move would impact current stats
	var currentTargetStats: Stats = target.combatant.stats
	var currentHighestElementBoost: float = 1.0
	if target.combatant.statChanges != null:
		statChanges.stack(target.combatant.statChanges)
		currentTargetStats = target.combatant.statChanges.apply(currentTargetStats)
		for elementBoost: ElementMultiplier in user.combatant.statChanges.elementMultipliers:
			currentHighestElementBoost = max(currentHighestElementBoost, elementBoost.multiplier)
	# apply directly to stats (includes current stat changes)
	var targetStats: Stats = statChanges.apply(target.combatant.stats)
	# calculate highest element boost after this move
	var highestElementBoost: float = 1.0
	for elementBoost: ElementMultiplier in statChanges.elementMultipliers:
		highestElementBoost = max(highestElementBoost, elementBoost.multiplier)
	# weight = old stat total / new stat total
	weight = currentTargetStats.get_stat_total_including_dmg_boosts(currentHighestElementBoost) / targetStats.get_stat_total_including_dmg_boosts(highestElementBoost)
	return weight

func _calc_self_weight(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode) -> float:
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(orbs)
	
	var selfWeight: float = 1.0
	var selfStatChanges: StatChanges = StatChanges.new()
	# if move has self stat changes: stack them
	if moveEffect.selfStatChanges != null:
		selfStatChanges.stack(moveEffect.selfStatChanges)
	if user == target and moveEffect.targetStatChanges != null:
		selfStatChanges.stack(moveEffect.targetStatChanges)
	# build currently applied user stats/element boosts first
	var selfCurrentStats: Stats = user.combatant.stats
	var selfCurrentElementBoost: float = 1.0
	if user.combatant.statChanges != null:
		# if the user already has stat changes, apply them to the self stat changes and to the current stats
		selfStatChanges.stack(user.combatant.statChanges)
		selfCurrentStats = user.combatant.statChanges.apply(user.combatant.stats)
		# get the highest current element boost
		for elementBoost: ElementMultiplier in user.combatant.statChanges.elementMultipliers:
			selfCurrentElementBoost = max(selfCurrentElementBoost, elementBoost.multiplier)
	# get the highest boost after applying this move's boosts
	var selfHighestElementBoost: float = 1.0
	# calc highest element boost on self
	for elementBoost: ElementMultiplier in selfStatChanges.elementMultipliers:
		selfHighestElementBoost = max(selfHighestElementBoost, elementBoost.multiplier)
	# new stats = apply this move's stat changes + currently applied changes
	var selfStats: Stats = selfStatChanges.apply(user.combatant.stats)
	# weight = new stat total / old stat total
	selfWeight = selfStats.get_stat_total_including_dmg_boosts(selfHighestElementBoost) / selfCurrentStats.get_stat_total_including_dmg_boosts(selfCurrentElementBoost)
	return selfWeight
