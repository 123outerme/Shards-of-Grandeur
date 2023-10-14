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
}

enum Type {
	NONE = 0,
	MOVE = 1,
	USE_ITEM = 2,
	ESCAPE = 3,
}

@export var type: Type = Type.NONE
@export var move: Move = null
@export var slot: InventorySlot = null
@export var targetPositions: Array[String] = []
@export var randomNum: float = 0

var targets: Array[Combatant] = []

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

static func is_command_multi_target(t: Targets) -> bool:
	return t == BattleCommand.Targets.ALL_ALLIES or t == BattleCommand.Targets.ALL_ENEMIES or t == BattleCommand.Targets.ALL_EXCEPT_SELF or t == BattleCommand.Targets.ALL

static func command_guard(combatantNode: CombatantNode) -> BattleCommand:
	return BattleCommand.new(
		Type.MOVE,
		load("res://GameData/Moves/guard.tres") as Move,
		null,
		[combatantNode.battlePosition],
		1.0, # consistent effects
	)

static func command_escape(allCombatants: Array[CombatantNode]) -> BattleCommand:
	var allPositions: Array[String] = []
	for combatantNode in allCombatants:
		allPositions.append(combatantNode.battlePosition)
	return BattleCommand.new(
		Type.ESCAPE,
		null,
		null,
		allPositions,
		randf(),
	)

func _init(
	i_type = Type.NONE,
	i_move = null,
	i_slot = null,
	i_targets: Array[String] = [],
	i_randomNum = 0.0,
):
	type = i_type
	move = i_move
	slot = i_slot
	targetPositions = i_targets
	randomNum = i_randomNum

func execute_command(user: Combatant, combatantNodes: Array[CombatantNode]) -> bool:
	get_targets_from_combatant_nodes(combatantNodes)
	if type == Type.ESCAPE:
		return get_is_escaping(user)
		
	for target in targets:
		var damage = calculate_damage(user, target)
		target.currentHp = min(max(target.currentHp - damage, 0), target.stats.maxHp) # bound to be at least 0 and no more than max HP
		if type == Type.MOVE and move.statusChance >= randomNum:
			target.statusEffect = move.statusEffect
	if type == Type.MOVE:
		user.statChanges.stack(move.statChanges)
	if type == Type.USE_ITEM:
		PlayerResources.inventory.trash_item(slot)
		
	return false

# logistic curve designed to dampen early-level ratio differences (ie lv 1 to lv 2 is a 2x increase, lv 10 to lv 11 is a 1.1x)
func dmg_logistic(userLv: int, targetLv: int) -> float:
	const lowBound: int = 1 # level-scaling "appears" to be Lv 1 at minimum
	var highBound: float = userLv # level-scaling approaches the actual user's level at maximum
	const e: float = 2.7182818 # approx.
	const horizShift: float = 6 # magic number to shift bounds (low bound to high bound between x=[0,10] summed-levels) at shift=6
	return lowBound + ( (highBound - lowBound) / (1.0 + pow(e, -1.0 * (userLv + targetLv - horizShift) )) )

func calculate_damage(user: Combatant, target: Combatant) -> int:
	var userStats: Stats = user.statChanges.apply(user.stats)
	var targetStats: Stats = target.statChanges.apply(target.stats)
	
	if type == Type.MOVE:
		var atkStat: float = userStats.physAttack # use physical for physical attacks
		if move.category == Move.DmgCategory.MAGIC:
			atkStat = userStats.magicAttack # use magic for magic attacks
		if move.category == Move.DmgCategory.AFFINITY:
			atkStat = userStats.affinity # use affinity for affinity-based attacks
		
		var atkExpression: float = atkStat + 5
		var resExpression: float = targetStats.resistance + 5
		var apparentLv = dmg_logistic(user.stats.level, target.stats.level) # "apparent" user levels:
		# scaled so that increases early on don't jack up the ratio intensely
		
		var damage: int = roundi( move.power * (apparentLv / 4.0) * (atkExpression / resExpression) )
		if move.power > 0 and damage <= 0:
			damage = 1 # if move IS a damaging move, make it do at least 1 damage
		
		return damage
	if type == Type.USE_ITEM: 
		if slot.item is Healing:
			var healItem: Healing = slot.item as Healing
			return -1 * healItem.healBy # static heal amount; not affected by affinity stat (negative to do healing and not damage)
	
	return 0 # otherwise there was no damage

func get_is_escaping(user: Combatant) -> bool:
	return true # TODO calculate if user escapes the battle based on the random num generated

func get_command_results(user: Combatant) -> String:
	var resultsText: String = user.disp_name() + ' passed.'
	var actionTargets: Targets = Targets.NONE
	
	if type == Type.MOVE:
		actionTargets = move.targets
		resultsText = user.disp_name()
		if actionTargets == Targets.ENEMY or actionTargets == Targets.ALL_ENEMIES:
			resultsText += ' attacked with ' + move.moveName
		else:
			resultsText += ' used ' + move.moveName
		if move.power > 0:
			resultsText += ', dealing '
		elif move.power < 0:
			resultsText += ', healing '
		else:
			resultsText += '' # TODO consider what to say with non-damaging buffs/debuffs	
	
	if type == Type.USE_ITEM:
		actionTargets = slot.item.battleTargets
		resultsText = user.disp_name() + ' used ' + slot.item.itemName
		if slot.item.itemType == Item.Type.HEALING:
			resultsText += '! Healed '
		#TODO do specific text for other types of in-battle items besides healing?
	
	# damage/healing/stat change effects
	if type == Type.MOVE or type == Type.USE_ITEM:
		for i in range(len(targets)):
			var target = targets[i]
			var targetName = target.disp_name()
			if target == user:
				targetName = 'self'
			if not target.downed:
				var damage: int = calculate_damage(user, target)
				if damage != 0:
					var damageText: String = TextUtils.num_to_comma_string(absi(damage))
					if damage > 0: # damage, not healing
						resultsText += damageText + ' damage to ' + targetName
					else:
						resultsText += targetName + ' by ' + damageText + ' HP'
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
		if type == Type.MOVE and move.statChanges.has_stat_changes():
			resultsText += ' ' + user.disp_name() + ' boosts '
			var multipliers: Array[StatMultiplierText] = move.statChanges.get_multipliers_text()
			for i in range(len(multipliers)):
				var multiplier: StatMultiplierText = multipliers[i]
				resultsText += multiplier.print_multiplier()
				if i < len(multipliers) - 1:
					if len(multipliers) > 2:
						resultsText += ','
					resultsText += ' '
					if i == len(multipliers) - 2:
						resultsText += 'and '
				else:
					resultsText += '.'
	if type == Type.ESCAPE:
		if get_is_escaping(user):
			resultsText = user.disp_name() + ' escaped the battle successfully!'
		else:
			resultsText = user.disp_name() + ' tried to escape, but could not get away!'
	
	return resultsText

func get_targets_from_combatant_nodes(combatantNodes: Array[CombatantNode]):
	targets = []
	for targetPos in targetPositions:
		for combatantNode in combatantNodes:
			if targetPos == combatantNode.battlePosition:
				targets.append(combatantNode.combatant)
