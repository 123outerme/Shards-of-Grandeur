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
@export var targets: Array[Combatant]
@export var randomNum: float = 0

static func command_guard(combatant: Combatant) -> BattleCommand:
	return BattleCommand.new(
		Type.MOVE,
		load("res://GameData/Moves/guard.tres") as Move,
		null,
		[combatant],
		1.0, # consistent effects
	)

static func command_escape() -> BattleCommand:
	return BattleCommand.new(
		Type.ESCAPE,
		null,
		null,
		[],
		randf(),
	)

func _init(
	i_type = Type.NONE,
	i_move = null,
	i_slot = null,
	i_targets: Array[Combatant] = [],
	i_randomNum = 0.0,
):
	type = i_type
	move = i_move
	slot = i_slot
	targets = i_targets
	randomNum = i_randomNum

func execute_command(user: Combatant):
	for target in targets:
		var damage = calculate_damage(user, target)
		target.currentHp -= damage
	if type == Type.MOVE:
		user.statChanges.stack(move.statChanges)

func calculate_damage(user: Combatant, target: Combatant) -> int:
	var userStats: Stats = user.statChanges.apply(user.stats)
	var targetStats: Stats = target.statChanges.apply(target.stats)
	
	# TODO figure out damage calculation
	return 1

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
			resultsText += '! Healed'
		#TODO do specific text for other types of in-battle items besides healing?
	
	# damage/healing/stat change effects
	if type == Type.MOVE or type == Type.USE_ITEM:
		for i in range(len(targets)):
			var target = targets[i]
			var targetName = target.disp_name()
			if target == user:
				targetName = 'self'
			if target.currentHp > 0:
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
				resultsText += multiplier.statName + ' ' + String.num(multiplier.multiplier) + 'x'
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
