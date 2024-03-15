extends Resource
class_name BattleCommand

enum Targets {
	NONE = 0, # for safety/readability, none means this isn't a valid battle action (using a non-battle item)
	SELF = 1, # only self is a valid target
	NON_SELF_ALLY = 2, # only valid target is an ally that is not the user
	ALLY = 3, # single-target one combatant on player's side
	ALL_ALLIES = 4, # multi-target all allies on player's side
	ENEMY = 5, # single-target one combatant on enemy side
	ALL_ENEMIES = 6, # multi-target one combatant on enemy side
	ALL_EXCEPT_SELF = 7, # multi-target every combatant except for self
	ALL = 8, # multi-target EVERY combatant, including self
	#ANY = 9, # single-target any combatant
	#ANY_EXCEPT_SELF = 10, # single-target any except self
}

enum Type {
	NONE = 0,
	MOVE = 1,
	USE_ITEM = 2,
	ESCAPE = 3,
}

enum ApplyTiming {
	BEFORE_BATTLE = 0,
	BEFORE_ROUND = 1,
	BEFORE_DMG_CALC = 2,
	DURING_DMG_CALC = 3,
	AFTER_DMG_CALC = 4,
	AFTER_ROUND = 5,
}

@export var type: Type = Type.NONE
@export var move: Move = null
@export var moveEffectType: Move.MoveEffectType = Move.MoveEffectType.NONE
@export var orbChange: int = 0
@export var slot: InventorySlot = null
@export var targetPositions: Array[String] = []
@export var randomNums: Array[float] = []
@export var commandResult: CommandResult = null

var targets: Array[Combatant] = []
var interceptingTargets: Array[Combatant] = []

static var hitParticles: ParticlePreset = preload("res://gamedata/moves/particles_hit.tres")

static func targets_to_string(t: Targets) -> String:
	match t:
		Targets.NONE:
			return 'None'
		Targets.SELF:
			return 'Self Only'
		Targets.NON_SELF_ALLY:
			return 'Any One Ally (Except Self)'
		Targets.ALLY:
			return 'Any One Ally'
		Targets.ALL_ALLIES:
			return 'All Allies'
		Targets.ENEMY:
			return 'Any One Enemy'
		Targets.ALL_ENEMIES:
			return 'All Enemies'
		Targets.ALL_EXCEPT_SELF:
			return 'All Combatants (Except Self)'
		Targets.ALL:
			return 'All Combatants'
	return 'UNKNOWN'

static func apply_timing_to_string(t: ApplyTiming) -> String:
	match t:
		ApplyTiming.BEFORE_BATTLE:
			return 'Before The Battle Begins'
		ApplyTiming.BEFORE_ROUND:
			return 'Before A Round Begins'
		ApplyTiming.BEFORE_DMG_CALC:
			return "Before The User's Turn Starts"
		ApplyTiming.DURING_DMG_CALC:
			return "During The User's Turn"
		ApplyTiming.AFTER_DMG_CALC:
			return "After The User's Turn Ends"
		ApplyTiming.AFTER_ROUND:
			return 'After The Round Ends'
	return 'UNKNOWN'

static func is_command_multi_target(t: Targets) -> bool:
	return t == BattleCommand.Targets.ALL_ALLIES or t == BattleCommand.Targets.ALL_ENEMIES or t == BattleCommand.Targets.ALL_EXCEPT_SELF or t == BattleCommand.Targets.ALL

static func is_command_enemy_targeting(t: Targets) -> bool:
	return t == BattleCommand.Targets.ALL or t == BattleCommand.Targets.ALL_ENEMIES or t == BattleCommand.Targets.ALL_EXCEPT_SELF or t == BattleCommand.Targets.ENEMY

'''
static func command_guard(combatantNode: CombatantNode) -> BattleCommand:
	return BattleCommand.new(
		Type.MOVE,
		load("res://gamedata/moves/guard/guard.tres") as Move,
		null,
		[combatantNode.battlePosition],
		[1.0], # consistent effects
	)
'''

static func command_escape(user: CombatantNode, allCombatants: Array[CombatantNode]) -> BattleCommand:
	var allPositions: Array[String] = []
	for combatantNode in allCombatants:
		if user.role != combatantNode.role: # only targets are enemies
			allPositions.append(combatantNode.battlePosition)
	return BattleCommand.new(
		Type.ESCAPE,
		null,
		null,
		allPositions,
	)

func _init(
	i_type = Type.NONE,
	i_move = null,
	i_effectType = Move.MoveEffectType.NONE,
	i_orbChange = 0,
	i_slot = null,
	i_targets: Array[String] = [],
	i_randomNums: Array[float] = [],
	i_commandResult: CommandResult = null
):
	type = i_type
	move = i_move
	moveEffectType = i_effectType
	orbChange = i_orbChange
	slot = i_slot
	targetPositions = i_targets
	if i_randomNums == [] and len(targetPositions) > 0: # if random nums are unset and the target positions are set:
		for target in targetPositions:
			i_randomNums.append(randf()) # get a random number for each
	elif len(i_randomNums) < len(targetPositions): # if some but not all random nums are set
		for i in range(len(randomNums), len(targetPositions)):
			randomNums.append(randomNums.back()) # append the last number to the end of the list of random nums
	randomNums = i_randomNums
	commandResult = i_commandResult
	
func set_targets(newTargets: Array[String]):
	targetPositions = newTargets.duplicate(false)
	if len(randomNums) == 0: # if random nums haven't been generated yet
		for target in targetPositions:
			randomNums.append(randf()) # generate random numbers now

func execute_command(user: Combatant, combatantNodes: Array[CombatantNode]) -> bool:
	commandResult = CommandResult.new()
	# TODO: rework stat boosts to use self/target stat changes
	var moveEffect: MoveEffect = null
	if move != null:
		moveEffect = move.get_effect_of_type(moveEffectType)
	
	for i in range(len(targets)):
		commandResult.damagesDealt.append(0)
		commandResult.afflictedStatuses.append(false)
		commandResult.wasBoosted.append(false)
	for i in range(len(interceptingTargets)):
		commandResult.damageOnInterceptingTargets.append(0)
	
	get_targets_from_combatant_nodes(combatantNodes)
	if type == Type.ESCAPE:
		return get_is_escaping(user)
	
	var appliedEffect: bool = false
	for idx in range(len(targets)):
		var finalPower = 0
		if type == Type.MOVE:
			finalPower = moveEffect.power
			for interceptIdx in range(len(interceptingTargets)):
				if interceptingTargets[interceptIdx] != targets[idx]:
					var interceptStatus: Interception = interceptingTargets[interceptIdx].statusEffect as Interception
					var interceptingPower: float = moveEffect.power * Interception.PERCENT_DAMAGE_DICT[interceptStatus.potency]
					finalPower -= interceptingPower
					var interceptedDmg = calculate_damage(user, interceptingTargets[interceptIdx], interceptingPower)
					commandResult.damageOnInterceptingTargets[interceptIdx] += interceptedDmg
					interceptingTargets[interceptIdx].currentHp = max(0, interceptingTargets[interceptIdx].currentHp - interceptedDmg)
					
		var damage = calculate_damage(user, targets[idx], finalPower)
		commandResult.damagesDealt[idx] += damage
		if damage != 0:
			appliedEffect = true
		targets[idx].currentHp = min(max(targets[idx].currentHp - damage, 0), targets[idx].stats.maxHp) # bound to be at least 0 and no more than max HP

		if does_target_get_status(user, idx) and moveEffect.statusEffect != null and targets[idx].statusEffect == null:
			targets[idx].statusEffect = moveEffect.statusEffect.copy()
			commandResult.afflictedStatuses[idx] = true
		
		if type == Type.USE_ITEM:
			if slot.item is Healing:
				if targets[idx].statusEffect != null and targets[idx].statusEffect.potency <= slot.item.statusStrengthHeal:
					targets[idx].statusEffect = null
					appliedEffect = true
				if slot.item.statChanges != null:
					targets[idx].statChanges.stack(slot.item.statChanges)
					#print(slot.item.itemName, ' stacks stat changes on ', targets[idx].disp_name())

		if moveEffect != null and \
				(moveEffect.targets == Targets.NON_SELF_ALLY or moveEffect.targets == Targets.ALL_ALLIES or moveEffect.targets == Targets.ALLY):
			targets[idx].statChanges.stack(moveEffect.targetStatChanges) # apply stat buffs
			commandResult.wasBoosted[idx] = true
	
	if type == Type.MOVE and moveEffect != null and BattleCommand.is_command_enemy_targeting(moveEffect.targets) or true in commandResult.afflictedStatuses:
		# if targets allies, fail to stack stats if status was not applied, otherwise stack
		user.statChanges.stack(moveEffect.selfStatChanges)

	if type == Type.USE_ITEM and appliedEffect: # item was used and healing was applied
		PlayerResources.inventory.trash_item(slot) # trash the item
		#print('TEST - trashed item ', slot.item.itemName)
	
	if type == Type.MOVE and moveEffect != null:
		user.add_orbs(orbChange) # add/subtract orbs from using move
	
	return false

# logistic curve designed to dampen early-level ratio differences (ie lv 1 to lv 2 is a 2x increase, lv 10 to lv 11 is a 1.1x)
func dmg_logistic(userLv: int, targetLv: int) -> float:
	const lowBound: int = 1 # level-scaling "appears" to be Lv 1 at minimum
	var highBound: float = userLv # level-scaling approaches the actual user's level at maximum
	const e: float = 2.7182818 # approx.
	const horizShift: float = 6 # magic number to shift bounds (low bound to high bound between x=[0,10] summed-levels) at shift=6
	return lowBound + ( (highBound - lowBound) / (1.0 + pow(e, -1.0 * (userLv + targetLv - horizShift) )) )

func calculate_damage(user: Combatant, target: Combatant, power: float, ignoreMoveStatChanges: bool = false) -> int:
	var userStatChanges = StatChanges.new()
	userStatChanges.stack(user.statChanges) # copy stat changes
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(target.statChanges)
	var moveEffect: MoveEffect = null
	if move != null:
		moveEffect = move.get_effect_of_type(moveEffectType)
	
	if ignoreMoveStatChanges and move != null: # ignore most recent move stat changes if move is after turn has been executed
		var isEnemyTargeting: bool = BattleCommand.is_command_enemy_targeting(moveEffect.targets)
		if (isEnemyTargeting and moveEffect.power > 0) or !(isEnemyTargeting and moveEffect.power < 0):
			if user == target: # if the user would be affected
				userStatChanges.undo_changes(moveEffect.selfStatChanges)
			targetStatChanges.undo_changes(moveEffect.targetStatChanges)
	
	var userStats: Stats = userStatChanges.apply(user.stats)
	var targetStats: Stats = targetStatChanges.apply(target.stats)
	
	if type == Type.MOVE:
		var atkStat: float = userStats.physAttack # use physical for physical attacks
		if move.category == Move.DmgCategory.MAGIC:
			atkStat = userStats.magicAttack # use magic for magic attacks
		if move.category == Move.DmgCategory.AFFINITY:
			atkStat = userStats.affinity # use affinity for affinity-based attacks
		
		var atkExpression: float = atkStat + 5
		var resExpression: float = targetStats.resistance + 5
		var apparentUserLv = dmg_logistic(user.stats.level, target.stats.level) # "apparent" user levels:
		# scaled so that increases early on don't jack up the ratio intensely
		var apparentTargetLv = dmg_logistic(target.stats.level, user.stats.level)
		
		var damage: int = roundi( power * ((apparentUserLv / apparentTargetLv) / 4.0) * (atkExpression / resExpression) )
		if power > 0 and damage <= 0:
			damage = 1 # if move IS a damaging move, make it do at least 1 damage
		
		return damage
	if type == Type.USE_ITEM and target.currentHp > 0: # if item and current target is still alive
		if slot.item is Healing: # if healing
			var healItem: Healing = slot.item as Healing
			return -1 * healItem.healBy # static heal amount; not affected by affinity stat (negative to do healing and not damage)
	
	return 0 # otherwise there was no damage

func calculate_escape_chance(user: Combatant, target: Combatant) -> float:
	# if target has Exhaustion status effect, and user doesn't have Exhaustion or has less potent Exhaustion, auto-pass
	if user.get_exhaustion_level() < target.get_exhaustion_level():
		return true
		
	# if user has Exhaustion, and target doesn't have Exhaustion or has less potent Exhaustion, auto-fail
	if user.get_exhaustion_level() > target.get_exhaustion_level():
		return false

	# otherwise, exhaustion levels are equal -> check speed stats
	var userStatChanges = StatChanges.new()
	userStatChanges.stack(user.statChanges) # copy stat changes
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(target.statChanges)
	var userStats = userStatChanges.apply(user.stats)
	var targetStats = targetStatChanges.apply(target.stats)
	# 90% flee base rate + 30% of (speed difference over speed totals)
	# => 90% flee base rate that increases as player speed increases (~proportional to stat scaling)
	# and decreases as target speed increases (~proportional to stat scaling
	return 0.9 + 0.3 * (userStats.speed - targetStats.speed) / (userStats.speed + targetStats.speed)

func which_target_prevents_escape(user: Combatant) -> int:
	var targetIdx = -1
	var lowestEscapeChance: float = 100000
	for idx in range(len(targets)):
		# if the best random number generated for the targets fails the escape chance, that target is blocking escape
		var chance = calculate_escape_chance(user, targets[idx])
		if randomNums.max() > chance and (chance < lowestEscapeChance or targetIdx == -1):
			lowestEscapeChance = chance
			targetIdx = idx # this specific enemy is preventing escape
	
	return targetIdx

func get_is_escaping(user: Combatant) -> bool:
	return which_target_prevents_escape(user) < 0

func does_target_get_status(user: Combatant, targetIdx: int) -> bool:
	# no move, no status, or no chance: auto-fail
	if move == null:
		return false
	var moveEffect: MoveEffect = move.get_effect_of_type(moveEffectType)
	if moveEffect == null or moveEffect.statusEffect == null or moveEffect.statusChance == 0:
		return false
	
	# status chance = 100%: auto-pass
	if moveEffect.statusChance == 1:
		return true
	
	var userStatChanges = StatChanges.new()
	userStatChanges.stack(user.statChanges) # copy stat changes
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(targets[targetIdx].statChanges)
	var userStats = userStatChanges.apply(user.stats)
	var targetStats = targetStatChanges.apply(targets[targetIdx].stats)
	return randomNums[targetIdx] <= moveEffect.statusChance + 0.3 * (userStats.affinity - targetStats.affinity) / (userStats.affinity + targetStats.affinity) 

func get_command_results(user: Combatant) -> String:
	var resultsText: String = user.disp_name() + ' passed.'
	if commandResult == null:
		return resultsText
	
	var actionTargets: Targets = Targets.NONE
	var selfDmg: int = 0
	var moveEffect: MoveEffect = null
	if move != null:
		moveEffect = move.get_effect_of_type(moveEffectType)
	
	if type == Type.MOVE:
		actionTargets = moveEffect.targets
		resultsText = user.disp_name()
		if actionTargets == Targets.ENEMY or actionTargets == Targets.ALL_ENEMIES:
			resultsText += ' attacked with ' + move.moveName
		else:
			resultsText += ' used ' + move.moveName + ' (' + Move.move_effect_type_to_string(moveEffectType) + ')'
		if moveEffect.power > 0:
			resultsText += ', dealing '
		elif moveEffect.power < 0:
			resultsText += ', healing '
		elif moveEffect.statusEffect != null:
			resultsText += ', '
	
	if type == Type.USE_ITEM:
		actionTargets = slot.item.battleTargets
		resultsText = user.disp_name() + ' used ' + slot.item.itemName
		if slot.item.itemType == Item.Type.HEALING:
			resultsText += '! Healed '
		#TODO do specific text for other types of in-battle items besides healing?
	
	# damage/healing/stat change effects
	if type == Type.MOVE or type == Type.USE_ITEM:
		var interceptingTargetDamages: Array[int] = []
		for i in range(len(interceptingTargets)):
			interceptingTargetDamages.append(0) # initialize intercepting target damage values
		
		for i in range(len(targets)):
			var target: Combatant = targets[i]
			var targetName = target.disp_name()
			if target == user:
				targetName = 'self'
			if not target.downed:
				var damage: int = commandResult.damagesDealt[i]
				if damage != 0:
					var damageText: String = TextUtils.num_to_comma_string(absi(damage))
					if damage > 0: # damage, not healing
						resultsText += damageText + ' damage to ' + targetName
					else:
						resultsText += targetName + ' by ' + damageText + ' HP'
					if type == Type.MOVE and commandResult.afflictedStatuses[i]:
						resultsText += ' and afflicting ' + moveEffect.statusEffect.status_effect_to_string()
				else:
					if type == Type.MOVE and moveEffect.statusEffect != null:
						if commandResult.afflictedStatuses[i]:
							resultsText += 'afflicting '
						else:
							resultsText += 'failing to afflict '
						resultsText += moveEffect.statusEffect.status_effect_to_string() + ' on ' + targetName
					if type == Type.USE_ITEM:
						if slot.item.itemType == Item.Type.HEALING:
							if slot.item.healBy != 0:
								resultsText += targetName + ' by not enough to help'
				if type == Type.USE_ITEM and slot.item.itemType == Item.Type.HEALING:
					var effectMsgs: Array[String] = []
					if slot.item.statusStrengthHeal != StatusEffect.Potency.NONE and target.statusEffect == null:
						effectMsgs.append('cured ' + StatusEffect.potency_to_string(slot.item.statusStrengthHeal) + ' status effects')
				
					if slot.item.statChanges != null:
						var multipliers: Array[StatMultiplierText] = slot.item.statChanges.get_multipliers_text()
						effectMsgs.append('boosted ' + StatMultiplierText.multiplier_text_list_to_string(multipliers))
					if len(effectMsgs) > 0:
						resultsText += ', '
						if len(effectMsgs) == 1:
							resultsText += 'and '
					for idx in range(len(effectMsgs)):
						resultsText += effectMsgs[idx]
						if idx < len(effectMsgs) - 2:
							resultsText += ', '
						if idx == len(effectMsgs) - 2:
							resultsText += 'and '
			else:
				if actionTargets == Targets.ENEMY or actionTargets == Targets.ALL_ENEMIES:
					resultsText += '... insult to injury on ' + targetName
				else:
					resultsText += '... but too little, too late for ' + target.disp_name() # don't use 'self'
		
			if i < len(targets) - 1:
				if len(targets) > 2:
					resultsText += ','
				resultsText += ' '
				if i == len(targets) - 2:
					resultsText += 'and '
			else:
				resultsText += '.'
		for interceptingIdx in range(len(interceptingTargets)):
			if commandResult.damageOnInterceptingTargets[interceptingIdx] > 0:
				resultsText += ' ' + interceptingTargets[interceptingIdx].disp_name() + ' intercepts ' + String.num(commandResult.damageOnInterceptingTargets[interceptingIdx]) + ' damage!'
		'''
		if type == Type.MOVE and moveEffect.statChanges != null:
			if moveEffect.statChanges.has_stat_changes() and not (not BattleCommand.is_command_enemy_targeting(moveEffect.targets) and not (true in commandResult.afflictedStatuses) and moveEffect.statusEffect != null):
				resultsText += ' ' + user.disp_name() + ' boosts '
				var displayTargetNames: bool = false
				for target in targets:
					if ((moveEffect.targets == Targets.ALLY or moveEffect.targets == Targets.ALL_ALLIES) and user != target) or moveEffect.targets == Targets.NON_SELF_ALLY:
						displayTargetNames = true
						break
				if displayTargetNames:
					var affectedTargets = get_multiplier_affected_targets()
					for i in range(len(affectedTargets)):
						var name: String = affectedTargets[i].disp_name()
						if affectedTargets[i] == user:
							name = 'self'
						resultsText += name
						if len(affectedTargets) > 1 and i < len(affectedTargets) - 1:
							resultsText += ', '
							if i == len(affectedTargets) - 2:
								resultsText += 'and '
					resultsText += ' with '
				
				var multipliers: Array[StatMultiplierText] = moveEffect.statChanges.get_multipliers_text()
				resultsText += StatMultiplierText.multiplier_text_list_to_string(multipliers) + '.'
		''' # TODO: fix stat changes to use self/target stat changes
	if type == Type.ESCAPE:
		var preventEscapingIdx: int = which_target_prevents_escape(user)
		if preventEscapingIdx < 0:
			resultsText = user.disp_name() + ' escaped the battle successfully!'
		else:
			resultsText = user.disp_name() + ' tried to escape, but ' + targets[preventEscapingIdx].disp_name() + ' blocked the way!'
	
	return resultsText

func get_targets_from_combatant_nodes(combatantNodes: Array[CombatantNode]):
	targets = []
	var targetNodes: Array[CombatantNode] = []
	for targetPos in targetPositions:
		for combatantNode in combatantNodes:
			if combatantNode.combatant != null:
				if targetPos == combatantNode.battlePosition:
					targets.append(combatantNode.combatant)
					targetNodes.append(combatantNode)
	interceptingTargets = []
	for combatantNode in combatantNodes:
		for targetNode in targetNodes:
			# if the combatant is alive, has the same role as one of the target(s), is not the target, and has the Interception status
			if combatantNode.combatant != null and \
					combatantNode.is_alive() and \
					combatantNode.role == targetNode.role and \
					combatantNode != targetNode and\
					combatantNode.combatant.statusEffect != null and \
					combatantNode.combatant.statusEffect.type == StatusEffect.Type.INTERCEPTION:
				interceptingTargets.append(combatantNode.combatant)
				break

func get_multiplier_affected_targets() -> Array[Combatant]:
	var affected: Array[Combatant] = []
	for idx in range(len(targets)):
		if commandResult.wasBoosted[idx]:
			affected.append(targets[idx])
	return affected

func get_command_animation() -> String:
	match type:
		Type.MOVE:
			match move.category:
				Move.DmgCategory.PHYSICAL:
					return 'attack_phys'
				Move.DmgCategory.MAGIC:
					return 'attack_magic'
				Move.DmgCategory.AFFINITY:
					return 'attack_affinity'
		Type.USE_ITEM:
			return 'talk'
		Type.ESCAPE:
			return 'walk'
	return 'stand'

func get_particles(combatantNode: CombatantNode, userNode: CombatantNode) -> Array[ParticlePreset]:
	var presets: Array[ParticlePreset] = []
	if commandResult == null:
		return []
	if combatantNode.combatant == userNode.combatant:
		# particles applied to the user
		match type:
			Type.MOVE:
				presets.append(move.moveAnimation.userParticlePreset)
			Type.USE_ITEM:
				return []
			Type.ESCAPE:
				return []
		return presets
	elif combatantNode.combatant in targets or combatantNode.combatant in interceptingTargets:
		# particles applied to the target(s)
		match type:
			Type.MOVE:
				presets.append(move.moveAnimation.targetsParticlePreset)
				var dmgTaken: float = 0
				var idx = targets.find(combatantNode.combatant)
				if idx >= 0 and commandResult.damagesDealt[idx] > 0:
					dmgTaken += commandResult.damagesDealt[idx]
				var interceptIdx = interceptingTargets.find(combatantNode.combatant)
				if interceptIdx >= 0 and commandResult.damageOnInterceptingTargets[interceptIdx] > 0:
					dmgTaken += commandResult.damageOnInterceptingTargets[interceptIdx]
				if dmgTaken > 0:
					var hitParticlesCopy = hitParticles.duplicate()
					hitParticlesCopy.count = max(2, min(6, 6 * (dmgTaken / combatantNode.combatant.stats.maxHp)))
					presets.append(hitParticlesCopy)
				
				return presets
			Type.USE_ITEM:
				return []
			Type.ESCAPE:
				return []
	return presets
