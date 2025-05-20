extends AbstractCombatantAiLayer
class_name DebuffCombatantAiLayer

enum DebuffStrategy {
	DEBUFF_WEAKEST = 0, ## attempt to debuff the weakest stat on the weakest available target
	DEBUFF_STRONGEST = 1, ## attempt to debuff the strongest stat on the strongest available target
}

@export var debuffStrategy: DebuffStrategy = DebuffStrategy.DEBUFF_STRONGEST

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[AbstractCombatantAiLayer] = [],
	i_debuffStrategy: DebuffStrategy = DebuffStrategy.DEBUFF_STRONGEST,
) -> void:
	super(i_weight, i_subLayers)
	debuffStrategy = i_debuffStrategy

## the stronger the debuff is based on the debuff strategy, the higher the weight
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState, allCombatantNodes: Array[CombatantNode]) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState, allCombatantNodes)
	if baseWeight < 0:
		return -1
	
	var moveWeight: float = 1
	
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(absi(orbs))
	
	var targetWeight: float = _calc_target_weight(user, move, effectType, orbs, target, battleState)
	var selfWeight: float = 1.0
	if user != target: # only if user is not the target (since we've already calc'd with target boosts)
		selfWeight = _calc_self_weight(user, move, effectType, orbs, target, battleState)
	moveWeight *= selfWeight * targetWeight
	
	if user.role != target.role:
		moveWeight = 1 / moveWeight
	
	return baseWeight * moveWeight

func _calc_target_weight(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, battleState: BattleState) -> float:
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(absi(orbs))
	
	var statChanges: StatChanges = StatChanges.new()
	var tWeight: float = 1.0
	# if there are target stat changes: stack them
	if moveEffect.targetStatChanges != null:
		statChanges.stack(moveEffect.targetStatChanges)
	if user == target and moveEffect.selfStatChanges != null:
		var canSelfStack: bool = true
		if BattleCommand.is_command_ally_targeting(moveEffect.targets) and moveEffect.statusEffect != null:
			# if the move is ally targetting, the status can't overwrite other statuses, and another status is already present on whoever will receive it: the boost isn't happening
			if not moveEffect.statusEffect.overwritesOtherStatuses and \
					((moveEffect.selfGetsStatus and user.combatant.statusEffect != null) or target.combatant.statusEffect != null):
				canSelfStack = false
		if canSelfStack:
			statChanges.stack(moveEffect.selfStatChanges)
	# calculate current stats, see how this move would impact current stats
	var currentTargetStats: Stats = target.combatant.stats
	var currentHighestElementBoost: float = 1.0
	if target.combatant.statChanges != null:
		statChanges.stack(target.combatant.statChanges)
		currentTargetStats = target.combatant.statChanges.apply(currentTargetStats)
		for elementBoost: ElementMultiplier in user.combatant.statChanges.elementMultipliers:
			currentHighestElementBoost = max(currentHighestElementBoost, elementBoost.multiplier)
	# stack boosts from any runes that this move could trigger
	for rune: Rune in AbstractCombatantAiLayer.get_runes_on_combatant_move_triggers(user, move, effectType, orbs, target, battleState, target.combatant.runes):
		statChanges.stack(rune.statChanges)
	# apply directly to stats (includes current stat changes)
	var targetStats: Stats = statChanges.apply(target.combatant.stats)
	# calculate highest element boost after this move
	var highestElementBoost: float = 1.0
	for elementBoost: ElementMultiplier in statChanges.elementMultipliers:
		highestElementBoost = max(highestElementBoost, elementBoost.multiplier)
	# weight = old stat total / new stat total
	tWeight = currentTargetStats.get_stat_total_including_dmg_boosts(currentHighestElementBoost) / targetStats.get_stat_total_including_dmg_boosts(highestElementBoost)
	return tWeight

func _calc_self_weight(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, battleState: BattleState) -> float:
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if effectType == Move.MoveEffectType.SURGE:
		moveEffect = moveEffect.apply_surge_changes(absi(orbs))
	
	var selfWeight: float = 1.0
	var selfStatChanges: StatChanges = StatChanges.new()
	# if move has self stat changes: stack them
	if moveEffect.selfStatChanges != null:
		var canSelfStack: bool = true
		if BattleCommand.is_command_ally_targeting(moveEffect.targets) and moveEffect.statusEffect != null:
			# if the move is ally targeting, the status can't overwrite other statuses, and another status is already present on whoever will receive it: the boost isn't happening
			if not moveEffect.statusEffect.overwritesOtherStatuses and \
					((moveEffect.selfGetsStatus and user.combatant.statusEffect != null) or target.combatant.statusEffect != null):
				canSelfStack = false
		if canSelfStack:
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
	# stack boosts from any runes that this move could trigger
	for rune: Rune in AbstractCombatantAiLayer.get_runes_on_combatant_move_triggers(user, move, effectType, orbs, target, battleState, user.combatant.runes):
		selfStatChanges.stack(rune.statChanges)
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

func copy(copyStorage: bool = false) -> DebuffCombatantAiLayer:
	return DebuffCombatantAiLayer.new(weight, copy_sublayers(copyStorage), debuffStrategy)
