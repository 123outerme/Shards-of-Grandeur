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
	ANY = 9, # single-target any combatant
	ANY_EXCEPT_SELF = 10, # single-target any except self
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
	AFTER_RECIEVING_DMG = 6,
	AFTER_POST_ROUND = 7, # only used for updating status effect turns
}

@export var type: Type = Type.NONE
@export var move: Move = null
@export var moveEffectType: Move.MoveEffectType = Move.MoveEffectType.NONE
@export var orbChange: int = 0
@export var slot: InventorySlot = null
@export var targetPositions: Array[String] = []
@export var randomNums: Array[float] = []
@export var selfRandomNum: float = -1
@export var decisionsRandomNum: float = -1
@export var commandResult: CommandResult = null

var targets: Array[Combatant] = []
var interceptingTargets: Array[Combatant] = []
var completingCommand: bool = false

static var hitParticles: ParticlePreset = preload("res://gamedata/moves/particles_hit.tres") as ParticlePreset
static var useItemAnimation: MoveAnimation = load('res://gamedata/items/use_item_animation.tres') as MoveAnimation

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
		Targets.ANY:
			return 'Any Combatant'
		Targets.ANY_EXCEPT_SELF:
			return 'Any Combatant (Except Self)'
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
		ApplyTiming.AFTER_RECIEVING_DMG:
			return 'After Taking An Attack'
	return 'UNKNOWN'

static func is_command_multi_target(t: Targets) -> bool:
	return t == Targets.ALL_ALLIES or t == Targets.ALL_ENEMIES or t == Targets.ALL_EXCEPT_SELF or t == Targets.ALL

static func is_command_enemy_targeting(t: Targets) -> bool:
	return t == Targets.ALL or t == Targets.ALL_ENEMIES or t == Targets.ALL_EXCEPT_SELF or t == Targets.ENEMY or t == Targets.ANY or t == Targets.ANY_EXCEPT_SELF

static func is_command_ally_targeting(t: Targets) -> bool:
	return t == Targets.ALL or t == Targets.ALL_ALLIES or t == Targets.ALL_EXCEPT_SELF or t == Targets.ALLY or t == Targets.NON_SELF_ALLY or t == Targets.ANY or t == Targets.ANY_EXCEPT_SELF

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
		Move.MoveEffectType.NONE,
		0,
		null,
		allPositions,
	)

# logistic curve designed to dampen early-level ratio differences (ie lv 1 to lv 2 is a 2x increase, lv 10 to lv 11 is a 1.1x)
static func dmg_logistic(userLv: int, targetLv: int) -> float:
	const lowBound: int = 1 # level-scaling "appears" to be Lv 1 at minimum
	var highBound: float = userLv # level-scaling approaches the actual user's level at maximum
	const e: float = 2.7182818 # approx.
	const horizShift: float = 6 # magic number to shift bounds (low bound to high bound between x=[0,10] summed-levels) at shift=6
	return lowBound + ( (highBound - lowBound) / (1.0 + pow(e, -1.0 * (userLv + targetLv - horizShift) )) )

static func damage_formula(power: float, atkStat: float, resistanceStat: float, userLv: int, targetLv: int, damageMultiplier: float) -> int:
	var atkExpression: float = round(atkStat * 1.1)
	if power < 0:
		atkExpression *= 2.5 # 2.5x heal multiplier
	var resExpression: float = round(resistanceStat * 0.9)
	if power < 0:
		resExpression = 5 # no resistance
	var apparentUserLv = BattleCommand.dmg_logistic(userLv, targetLv) # "apparent" user levels:
	# scaled so that increases early on don't jack up the ratio intensely
	var apparentTargetLv = BattleCommand.dmg_logistic(targetLv, userLv)
	var usrLvMultiplier: float = 1 + (0.05 * apparentUserLv)
	var statCheckMultiplier: float = 1 + (0.05 * (atkExpression - resExpression))
	#print('power: ', power, '\nusr lv mult: ', usrLvMultiplier, '\natk: ', atkExpression, '\nres: ', resExpression)
	#print('apparent usr lv: ', apparentUserLv, '\napparent target lv: ', apparentTargetLv)
	var damage: int = roundi( power * usrLvMultiplier * (1 / 3.75) * statCheckMultiplier * damageMultiplier )
	# if move IS a damaging move, make it do at least ceiling[AttackerLv / 2] damage
	var minDmg: int = ceili(userLv / 2.0)
	if power > 0 and damage < minDmg:
		damage = minDmg 
	return damage

static func setup_status(user: Combatant, target: Combatant, statusEffect: StatusEffect, power: int, dmgCategory: Move.DmgCategory, element: Move.Element, keywords: Array[String], damage: int) -> void:
	if statusEffect.type == StatusEffect.Type.NONE:
		target.statusEffect = null
	else:
		target.statusEffect = statusEffect.copy()
		if statusEffect.type == StatusEffect.Type.ELEMENT_BURN:
			var elementBurn: ElementBurn = target.statusEffect as ElementBurn
			# save the attacker's current stats to the element burn
			var userStatChanges = StatChanges.new()
			userStatChanges.stack(user.statChanges) # copy stat changes
			var userStats: Stats = userStatChanges.apply(user.stats)
			if user.statusEffect != null and user.statusEffect.is_stat_altering():
				userStats = user.statusEffect.apply_stat_change(userStats)
			
			var atkStat: float = userStats.physAttack # use physical for physical attacks
			if dmgCategory == Move.DmgCategory.MAGIC:
				atkStat = userStats.magicAttack # use magic for magic attacks
			if dmgCategory == Move.DmgCategory.AFFINITY:
				atkStat = userStats.affinity # use affinity for affinity-based attacks
			# An ally w/ Intercept should NOT reduce the power of the burn
			var elMultiplier: float = 1.0
			if user.statChanges != null:
				elMultiplier = user.statChanges.get_element_multiplier(element)
			
			var burnPower: float = power
			# if the status has preset power, use that instead: 
			if elementBurn.power > 0:
				burnPower = elementBurn.power
			elementBurn.set_burn_damage_parameters(burnPower * elMultiplier, atkStat, user.stats.level)
		elif statusEffect.type == StatusEffect.Type.ENDURE:
			var endure: Endure = target.statusEffect as Endure
			# save the afflicted's current HP to the endure (in case it's already less than the Endure HP minimum)
			endure.lowestHp = target.currentHp
			# if a move was damaging, don't consider the currently taken damage for the lowestHp
			if damage > 0:
				endure.lowestHp += damage

func _init(
	i_type = Type.NONE,
	i_move = null,
	i_effectType = Move.MoveEffectType.NONE,
	i_orbChange = 0,
	i_slot = null,
	i_targets: Array[String] = [],
	i_randomNums: Array[float] = [],
	i_selfRandomNum: float = -1,
	i_decisionsRandomNum: float = -1,
	i_commandResult: CommandResult = null
):
	type = i_type
	move = i_move
	moveEffectType = i_effectType
	orbChange = i_orbChange
	slot = i_slot
	targetPositions = i_targets
	if len(i_randomNums) == 0 and len(targetPositions) > 0: # if random nums are unset and the target positions are set:
		for target in targetPositions:
			i_randomNums.append(randf()) # get a random number for each
	elif len(i_randomNums) < len(targetPositions): # if some but not all random nums are set
		for i in range(len(randomNums), len(targetPositions)):
			randomNums.append(randomNums.back()) # append random numbers to the end of the list of random nums to match the length of targets
	randomNums = i_randomNums
	selfRandomNum = i_selfRandomNum
	if selfRandomNum == -1:
		selfRandomNum = randf()
	decisionsRandomNum = i_decisionsRandomNum
	if decisionsRandomNum == -1:
		decisionsRandomNum = randf()
	commandResult = i_commandResult
	
func set_targets(newTargets: Array[String]):
	targetPositions = newTargets.duplicate(false)
	if len(randomNums) == 0: # if random nums haven't been generated yet
		for target in targetPositions:
			randomNums.append(randf()) # generate random numbers now
	if selfRandomNum == -1:
		selfRandomNum = randf()

func execute_command(user: Combatant, combatantNodes: Array[CombatantNode], battleState: BattleState) -> bool:
	commandResult = CommandResult.new()
	var moveEffect: MoveEffect = null
	if move != null:
		moveEffect = move.get_effect_of_type(moveEffectType)
		if moveEffectType == Move.MoveEffectType.SURGE: # apply surge effects
			moveEffect = moveEffect.apply_surge_changes(absi(orbChange))
		if moveEffect.selfHpSacrifice > 0:
			var sacrificeDmg: int = roundi(user.stats.maxHp * moveEffect.selfHpSacrifice)
			commandResult.selfHpSacrificed += sacrificeDmg
			user.currentHp -= sacrificeDmg
	
	get_targets_from_combatant_nodes(combatantNodes)
	
	for i in range(len(targets)):
		commandResult.damagesDealt.append(0)
		commandResult.afflictedStatuses.append(false)
		commandResult.wasBoosted.append(false)
		commandResult.equipmentProcd.append([])
	for i in range(len(interceptingTargets)):
		commandResult.damageOnInterceptingTargets.append(0)
	if type == Type.ESCAPE:
		return get_is_escaping(user)
	
	var appliedEffect: bool = false
	var totalInflictedDamage: int = 0
	for idx in range(len(targets)):
		if targets[idx].currentHp <= 0:
			continue # skip already downed opponents
		var finalPower = 0
		if type == Type.MOVE:
			finalPower = moveEffect.power
			for interceptIdx in range(len(interceptingTargets)):
				# if the interceptor is not the target, and this move is not healing:
				if interceptingTargets[interceptIdx] != targets[idx] and finalPower > 0:
					var interceptStatus: Interception = interceptingTargets[interceptIdx].statusEffect as Interception
					var interceptingPower: float = moveEffect.power * Interception.PERCENT_DAMAGE_DICT[interceptStatus.potency]
					finalPower -= interceptingPower
					var interceptedDmg: int = calculate_damage(user, interceptingTargets[interceptIdx], interceptingPower)
					totalInflictedDamage += interceptedDmg
					commandResult.damageOnInterceptingTargets[interceptIdx] += interceptedDmg
					interceptingTargets[interceptIdx].currentHp = min(max(0, interceptingTargets[interceptIdx].currentHp - interceptedDmg), interceptingTargets[interceptIdx].stats.maxHp)
					
		var damage: int = calculate_damage(user, targets[idx], finalPower)
		totalInflictedDamage += damage
		commandResult.damagesDealt[idx] += damage
		if targets[idx].currentHp > 0:
			targets[idx].currentHp = min(max(targets[idx].currentHp - damage, 0), targets[idx].stats.maxHp) # bound to be at least 0 and no more than max HP

		if does_target_get_status(user, idx) and moveEffect.statusEffect != null:
			BattleCommand.setup_status(user, targets[idx], moveEffect.statusEffect, moveEffect.power, move.category, move.element, moveEffect.keywords, damage)
			commandResult.afflictedStatuses[idx] = true
		
		if type == Type.USE_ITEM:
			if slot.item is Healing:
				if abs(damage) > 0:
					appliedEffect = true
				if targets[idx].statusEffect != null and targets[idx].statusEffect.potency <= slot.item.statusStrengthHeal:
					targets[idx].statusEffect = null
					commandResult.afflictedStatuses[idx] = true
					appliedEffect = true
				if slot.item.statChanges != null and slot.item.statChanges.has_stat_changes():
					targets[idx].statChanges.stack(slot.item.statChanges)
					#print(slot.item.itemName, ' stacks stat changes on ', targets[idx].disp_name())

		if moveEffect != null and moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes():
			if not (moveEffect.statusEffect != null and not commandResult.afflictedStatuses[idx] and \
					(moveEffect.statusRequiredForTargetStatChanges or moveEffect.targets == Targets.NON_SELF_ALLY or moveEffect.targets == Targets.ALL_ALLIES or moveEffect.targets == Targets.ALLY or moveEffect.targets == Targets.SELF)):
				targets[idx].statChanges.stack(moveEffect.targetStatChanges) # apply stat buffs
				commandResult.wasBoosted[idx] = true
	
	if type == Type.MOVE:
		if moveEffect.selfGetsStatus and user not in targets:
			if does_target_get_status(user, -1) and moveEffect.statusEffect != null:
				BattleCommand.setup_status(user, user, moveEffect.statusEffect, moveEffect.power, move.category, move.element, moveEffect.keywords, 0)
				commandResult.selfAfflictedStatus = true
		
		if moveEffect != null and (BattleCommand.is_command_enemy_targeting(moveEffect.targets) or not (moveEffect.statusEffect != null and not (commandResult.selfAfflictedStatus or (true in commandResult.afflictedStatuses)))):
			# if targets allies, fail to stack stats if status was not applied, otherwise stack
			if moveEffect.selfStatChanges != null:
				user.statChanges.stack(moveEffect.selfStatChanges)
				var userTargetIdx: int = targets.find(user)
				if userTargetIdx > -1:
					commandResult.wasBoosted[userTargetIdx] = true
				commandResult.selfBoosted = true
				
		if moveEffect != null and moveEffect.lifesteal > 0 and totalInflictedDamage > 0:
			var hpHealed: int = max(1, roundi(max(0, moveEffect.lifesteal) * totalInflictedDamage))
			commandResult.lifestealHeal = hpHealed
			user.currentHp = max(0, min(user.stats.maxHp, user.currentHp + hpHealed))

	if type == Type.USE_ITEM and appliedEffect: # item was used and healing was applied
		PlayerResources.inventory.trash_item(slot) # trash the item
		#print('TEST - trashed item ', slot.item.itemName)
	
	if type == Type.MOVE and moveEffect != null:
		user.add_orbs(orbChange) # add/subtract orbs from using move
		
	if type == Type.MOVE and moveEffect != null and moveEffect.rune != null and Combatant.are_runes_allowed():
		# after everything else in the command has processed, set up runes
		for target: Combatant in targets:
			var newRune: Rune = moveEffect.rune.copy()
			newRune.init_rune_state(target, [user], battleState)
			target.runes.append(newRune)
	
	return false

func calculate_damage(user: Combatant, target: Combatant, power: float, ignoreMoveStatChanges: bool = false) -> int:
	var userStatChanges = StatChanges.new()
	userStatChanges.stack(user.statChanges) # copy stat changes
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(target.statChanges)
	var moveEffect: MoveEffect = null
	var damageMultiplier: float = 1.0
	if move != null:
		moveEffect = move.get_effect_of_type(moveEffectType)
		# don't consider element effectiveness matchup with healing moves
		if power > 0:
			damageMultiplier = target.get_element_effectiveness_multiplier(move.element)
		# but do consider the elemental multiplier
		damageMultiplier *= user.statChanges.get_element_multiplier(move.element)

		# gather total keyword multiplier:
		var keywordMultiplier: float = 1.0
		for keyword: String in moveEffect.keywords:
			keywordMultiplier += user.statChanges.get_keyword_multiplier(keyword) - 1.0
		# and multiply it into the final damage multiplier
		damageMultiplier *= keywordMultiplier

	if ignoreMoveStatChanges and move != null: # ignore most recent move stat changes if move is after turn has been executed
		var isEnemyTargeting: bool = BattleCommand.is_command_enemy_targeting(moveEffect.targets)
		if (isEnemyTargeting and moveEffect.power > 0) or !(isEnemyTargeting and moveEffect.power < 0):
			if user == target and moveEffect.selfStatChanges != null: # if the user would be affected
				userStatChanges.undo_changes(moveEffect.selfStatChanges)
			if moveEffect.targetStatChanges != null:
				targetStatChanges.undo_changes(moveEffect.targetStatChanges)
	
	var userStats: Stats = userStatChanges.apply(user.stats)
	if user.statusEffect != null and user.statusEffect.is_stat_altering():
		userStats = user.statusEffect.apply_stat_change(userStats)
	
	var targetStats: Stats = targetStatChanges.apply(target.stats)
	if target.statusEffect != null and target.statusEffect.is_stat_altering():
		targetStats = target.statusEffect.apply_stat_change(targetStats)
	
	if type == Type.MOVE:
		var atkStat: float = userStats.physAttack # use physical for physical attacks
		if move.category == Move.DmgCategory.MAGIC:
			atkStat = userStats.magicAttack # use magic for magic attacks
		if move.category == Move.DmgCategory.AFFINITY:
			atkStat = userStats.affinity # use affinity for affinity-based attacks
		return BattleCommand.damage_formula(power, atkStat, targetStats.resistance, user.stats.level, target.stats.level, damageMultiplier)
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
	if user.statusEffect != null and user.statusEffect.is_stat_altering():
		userStats = user.statusEffect.apply_stat_change(userStats)
	
	var targetStats = targetStatChanges.apply(target.stats)
	if target.statusEffect != null and target.statusEffect.is_stat_altering():
		targetStats = target.statusEffect.apply_stat_change(targetStats)
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

func get_command_priority() -> int:
	if type == Type.MOVE and move != null:
		var moveEffect: MoveEffect = move.get_effect_of_type(moveEffectType)
		if moveEffect:
			return moveEffect.priority
	return 0

func does_target_get_status(user: Combatant, targetIdx: int) -> bool:
	# no move, no status, or no chance: auto-fail
	if move == null:
		return false
	var moveEffect: MoveEffect = move.get_effect_of_type(moveEffectType)
	if moveEffect == null or moveEffect.statusEffect == null or moveEffect.statusChance == 0:
		return false
	
	var target: Combatant = targets[targetIdx] if targetIdx >= 0 else user
	
	# if the target already has a status, and:
	# the move does not overwrite other statuses, or it does but the existing status is more potent: fail
	if target.statusEffect != null:
		if not moveEffect.statusEffect.overwritesOtherStatuses or target.statusEffect.potency > moveEffect.statusEffect.potency:
			return false
	elif moveEffect.statusEffect.type == StatusEffect.Type.NONE:
		return false # cannot cure status if there is no status
	
	var statusEffectivenessMultiplier: float = 1
	if user != target:
		statusEffectivenessMultiplier = target.get_status_effectiveness_multiplier(moveEffect.statusEffect.type)
	var statusChance: float = moveEffect.statusChance * statusEffectivenessMultiplier
	
	# status chance = 100%: auto-pass
	if statusChance == 1:
		return true
	
	var userStatChanges = StatChanges.new()
	userStatChanges.stack(user.statChanges) # copy stat changes
	var targetStatChanges = StatChanges.new()
	targetStatChanges.stack(target.statChanges)
	var userStats = userStatChanges.apply(user.stats)
	if user.statusEffect != null and user.statusEffect.is_stat_altering():
		userStats = user.statusEffect.apply_stat_change(userStats)

	var targetStats = targetStatChanges.apply(target.stats)
	if target.statusEffect != null and target.statusEffect.is_stat_altering():
		targetStats = target.statusEffect.apply_stat_change(targetStats)
	
	var randomNum: float = randomNums[targetIdx] if targetIdx >= 0 else selfRandomNum
	
	return randomNum <= statusChance + \
			0.3 * (userStats.affinity - targetStats.affinity) / (userStats.affinity + targetStats.affinity)

func get_command_results(user: Combatant) -> String:
	var resultsText: String = user.disp_name() + ' passed.'
	if commandResult == null:
		return resultsText
	
	var actionTargets: Targets = Targets.NONE
	var moveEffect: MoveEffect = null
	var userIdx: int = targets.find(user)
	if move != null:
		moveEffect = move.get_effect_of_type(moveEffectType)
		if moveEffectType == Move.MoveEffectType.SURGE: # apply surge effects
			moveEffect = moveEffect.apply_surge_changes(absi(orbChange))
	
	if type == Type.MOVE:
		actionTargets = moveEffect.targets
		# "User (Charged/Surged with)/(used) Move"
		var moveEffTypeString: String = 'used ' # if surge hasn't been unlocked yet, just say used
		if Combatant.are_surge_moves_allowed():
			# if surge HAS been unlocked, specify which
			moveEffTypeString = Move.move_effect_type_to_string(moveEffectType) + 'd with '
		
		resultsText = user.disp_name() + ' ' + moveEffTypeString + move.moveName
		
		if orbChange != 0:
			# ", gaining/spending X Orb(s)"
			if orbChange > 0:
				resultsText += ', gaining '
			else:
				resultsText += ', spending '
			resultsText += String.num_int64(abs(orbChange)) + ' $orb'
		
		if commandResult.selfHpSacrificed > 0:
			resultsText += ', and sacrificing ' + TextUtils.num_to_comma_string(commandResult.selfHpSacrificed) + ' HP'

		# "dealt/healed/afflicted "
		if moveEffect.power > 0:
			resultsText += '.\n' + user.disp_name() + ' dealt '
		elif moveEffect.power < 0:
			resultsText += '.\n' + user.disp_name() + ' healed '
		elif moveEffect.statusEffect != null:
			resultsText += '.\n' + user.disp_name() + ' '# If the damage was 0, we take care of the "afflicted" text below
	
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
		
		# print damages dealt, statuses afflicted on targets
		for i in range(len(targets)):
			var target: Combatant = targets[i]
			var targetName: String = target.disp_name()
			var targetResultText: String = ''
			if target == user:
				targetName = 'self'
			if not target.downed:
				var damage: int = commandResult.damagesDealt[i]
				if damage != 0:
					# if damage was dealt
					var moveElString: String = ' '
					if type == Type.MOVE:
						var elEffectivenessMultiplier = target.get_element_effectiveness_multiplier(move.element)
						if elEffectivenessMultiplier == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective:
							moveElString += 'super-effective '
						elif elEffectivenessMultiplier == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.resisted:
							moveElString += 'resisted '
						if move.element != Move.Element.NONE:
							# add a space here so below we don't need to check whether this is empty
							moveElString += Move.element_to_string(move.element) + ' '

					var damageText: String = TextUtils.num_to_comma_string(absi(damage))
					if damage > 0: # damage, not healing
						targetResultText += damageText + moveElString + 'damage to ' + targetName
					else:
						targetResultText += targetName + ' by ' + damageText + ' HP'
					if type == Type.MOVE and moveEffect.statusEffect != null:
						if commandResult.afflictedStatuses[i]:
							if moveEffect.statusEffect.type != StatusEffect.Type.NONE:
								targetResultText += ' and afflicted ' + moveEffect.statusEffect.status_effect_to_string()
							else:
								targetResultText += ' and cured ' + StatusEffect.potency_to_string(moveEffect.statusEffect.potency) + ' statuses'
						else:
							if target.get_status_effectiveness_multiplier(moveEffect.statusEffect.type) == Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.immune:
								targetResultText += ', but the ' + moveEffect.statusEffect.get_status_type_string() + ' was nullified'
							elif target.get_status_effectiveness_multiplier(moveEffect.statusEffect.type) == Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.resisted:
								targetResultText += ', but the ' + moveEffect.statusEffect.get_status_type_string() + ' was resisted'
							else:
								targetResultText += ', but failed to afflict ' + moveEffect.statusEffect.get_status_type_string()
				else:
					# if no damage was dealt
					if type == Type.MOVE and moveEffect.statusEffect != null:
						if commandResult.afflictedStatuses[i]:
							if moveEffect.statusEffect.type != StatusEffect.Type.NONE:
								targetResultText += 'afflicted '
							else:
								targetResultText += 'cured '
						else:
							if moveEffect.statusEffect.type != StatusEffect.Type.NONE:
								targetResultText += 'failed to afflict '
							else:
								targetResultText += 'failed to cure '
						if moveEffect.statusEffect.type != StatusEffect.Type.NONE:
							targetResultText += moveEffect.statusEffect.status_effect_to_string() + ' on '
						else:
							targetResultText += StatusEffect.potency_to_string(moveEffect.statusEffect.potency) + ' status on '
						if target.get_status_effectiveness_multiplier(moveEffect.statusEffect.type) == Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.immune:
							targetResultText += 'the immune '
						elif target.get_status_effectiveness_multiplier(moveEffect.statusEffect.type) == Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.resisted:
							targetResultText += 'the resisting '
						targetResultText += targetName
					if type == Type.USE_ITEM:
						if slot.item.itemType == Item.Type.HEALING:
							if slot.item.healBy != 0:
								targetResultText += targetName + ' by not enough to help'
				if type == Type.USE_ITEM and slot.item.itemType == Item.Type.HEALING:
					var effectMsgs: Array[String] = []
					if slot.item.statusStrengthHeal != StatusEffect.Potency.NONE and target.statusEffect == null:
						effectMsgs.append('cured ' + StatusEffect.potency_to_string(slot.item.statusStrengthHeal) + ' status effects')
				
					if slot.item.statChanges != null:
						var multipliers: Array[StatMultiplierText] = slot.item.statChanges.get_multipliers_text()
						effectMsgs.append('boosted ' + StatMultiplierText.multiplier_text_list_to_string(multipliers))
					if len(effectMsgs) > 0:
						targetResultText += ', '
						if len(effectMsgs) == 1:
							targetResultText += 'and '
					for idx in range(len(effectMsgs)):
						targetResultText += effectMsgs[idx]
						if idx < len(effectMsgs) - 2:
							targetResultText += ', '
						if idx == len(effectMsgs) - 2:
							targetResultText += 'and '
			else:
				if actionTargets == Targets.ENEMY or actionTargets == Targets.ALL_ENEMIES:
					targetResultText += '... insult to injury on ' + targetName
				else:
					targetResultText += '... but too little, too late for ' + target.disp_name() # don't use 'self'
			
			resultsText += targetResultText
			if targetResultText != '':
				if i < len(targets) - 1:
					if len(targets) > 2:
						resultsText += ','
					resultsText += ' '
					if i == len(targets) - 2:
						resultsText += 'and '
				else:
					resultsText += '!'
			elif i == len(targets) - 1:
				resultsText += '!'
		
		# print damages dealt to intercepting targets
		for interceptingIdx in range(len(interceptingTargets)):
			if commandResult.damageOnInterceptingTargets[interceptingIdx] > 0:
				var moveElString: String = ' '
				if type == Type.MOVE:
					var elEffectivenessMultiplier = interceptingTargets[interceptingIdx].get_element_effectiveness_multiplier(move.element)
					if elEffectivenessMultiplier == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective:
						moveElString += 'super-effective '
					elif elEffectivenessMultiplier == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.resisted:
						moveElString += 'resisted '
					if move.element != Move.Element.NONE:
						# add a space here so below we don't need to check whether this is empty
						moveElString += Move.element_to_string(move.element) + ' '
				resultsText += ' ' + interceptingTargets[interceptingIdx].disp_name() + ' intercepted ' + \
						String.num_int64(commandResult.damageOnInterceptingTargets[interceptingIdx]) + moveElString + 'damage!'
		if type == Type.MOVE and moveEffect.lifesteal > 0 and commandResult.lifestealHeal > 0:
			resultsText += '\n' + user.disp_name() + ' stole ' + String.num_int64(commandResult.lifestealHeal) + ' HP from the target'
			if len(targets) != 1:
				resultsText += 's'
			resultsText += '!'
		
		# print stat changes on user, targets
		if type == Type.MOVE and ( \
					(moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes() and commandResult.selfBoosted) \
					or (moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes()) \
				) and (true in commandResult.wasBoosted or commandResult.selfBoosted):
			var atLeastOneTargetBoosted: bool = moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes() and commandResult.selfBoosted
			for targetIdx in range(len(targets)):
				if commandResult.wasBoosted[targetIdx]:
					atLeastOneTargetBoosted = true
					break
			if atLeastOneTargetBoosted:
				resultsText += '\n' + user.disp_name() + ' boosted '
				if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes() and \
						((userIdx > -1 and commandResult.wasBoosted[userIdx]) or commandResult.wasBoosted):
					var selfStatChanges = moveEffect.selfStatChanges.copy()
					if moveEffect.targetStatChanges != null and userIdx > -1 and commandResult.wasBoosted[userIdx]:
						selfStatChanges.stack(moveEffect.targetStatChanges)
					var multipliers: Array[StatMultiplierText] = selfStatChanges.get_multipliers_text()
					resultsText += 'self ' + StatMultiplierText.multiplier_text_list_to_string(multipliers)
				if moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes() and true in commandResult.wasBoosted:
					var targetStatChangesText: String = ''
					if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
						targetStatChangesText += ', and '
					var hasOneTarget: bool = false
					for targetIdx in range(len(targets)):
						if (moveEffect.targets == Targets.NON_SELF_ALLY or moveEffect.targets == Targets.ALL_ALLIES or moveEffect.targets == Targets.ALLY) and \
								not commandResult.wasBoosted[targetIdx]:
							continue # combatant was not boosted
						var target = targets[targetIdx]
						if target == user:
							if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes() and moveEffect.targetStatChanges != null and commandResult.selfBoosted:
								continue # we already printed the user's stat changes
							targetStatChangesText += 'self'
						else:
							targetStatChangesText += target.disp_name()
						hasOneTarget = true
						if targetIdx == len(targets) - 2:
							if len(targets) > 2:
								targetStatChangesText += ','
							targetStatChangesText += ' and '
						elif targetIdx < len(targets) - 1 and len(targets) > 2:
							targetStatChangesText += ', '
					var multipliers: Array[StatMultiplierText] = moveEffect.targetStatChanges.get_multipliers_text()
					targetStatChangesText += ' ' + StatMultiplierText.multiplier_text_list_to_string(multipliers)
					if hasOneTarget: # only show if one target was validly affected
						resultsText += targetStatChangesText
				resultsText += '.'
		# print rune having been applied
		if type == Type.MOVE:
			if moveEffect != null and moveEffect.rune != null and Combatant.are_runes_allowed():
				resultsText += '\n'
				for i in range(len(targets)):
					var target: Combatant = targets[i]
					resultsText += target.disp_name()
					if i < len(targets) - 2:
						resultsText += ', '
					elif i < len(targets) - 1:
						resultsText += ', and '
				if len(targets) == 1:
					resultsText += ' was'
				else:
					resultsText += ' were'
				resultsText += ' enchanted with a ' + moveEffect.rune.get_long_rune_type() + '!'
				
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
					combatantNode != targetNode and \
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
			return move.moveAnimation.combatantAnimation
		Type.USE_ITEM:
			return ''
		Type.ESCAPE:
			return 'walk'
	return 'stand'

func get_command_sprites() -> Array[MoveAnimSprite]:
	if type == Type.MOVE:
		if moveEffectType == Move.MoveEffectType.CHARGE:
			return move.moveAnimation.chargeMoveSprites
		if moveEffectType == Move.MoveEffectType.SURGE:
			return move.moveAnimation.surgeMoveSprites
	if type == Type.USE_ITEM:
		var a = useItemAnimation
		return a.chargeMoveSprites
	return []

func get_command_battlefield_shade_anim() -> BattlefieldShadeAnim:
	if type == Type.MOVE:
		if moveEffectType == Move.MoveEffectType.CHARGE:
			return move.moveAnimation.chargeBattlefieldShade
		if moveEffectType == Move.MoveEffectType.SURGE:
			return move.moveAnimation.surgeBattlefieldShade
	if type == Type.USE_ITEM:
		var a = useItemAnimation
		return a.chargeBattlefieldShade
	return null

func get_particles(combatantNode: CombatantNode, userNode: CombatantNode, isTarget: bool = true) -> Array[ParticlePreset]:
	var presets: Array[ParticlePreset] = []
	if commandResult == null:
		return []
	if combatantNode.combatant == userNode.combatant:
		# particles applied to the user
		match type:
			Type.MOVE:
				presets.append(move.moveAnimation.userParticlePreset)
				if isTarget:
					presets.append(move.moveAnimation.targetsParticlePreset)
			Type.USE_ITEM:
				return [useItemAnimation.userParticlePreset]
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
					var hitParticlesCopy = BattleCommand.get_hit_particles()
					hitParticlesCopy.count = max(2, min(6, 6 * (dmgTaken / combatantNode.combatant.stats.maxHp)))
					presets.append(hitParticlesCopy)
				
				return presets
			Type.USE_ITEM:
				return []
			Type.ESCAPE:
				return []
	return presets

static func get_hit_particles():
	return hitParticles.duplicate()
