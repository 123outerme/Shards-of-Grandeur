extends StatusEffect
class_name Endure

const MIN_PERCENT_HP_DICT: Dictionary[Potency, float] = {
	Potency.NONE: 0,
	Potency.WEAK: 0.01,
	Potency.STRONG: 0.05,
	Potency.OVERWHELMING: 0.1
}

const ENDURE_AT_BARRIER_CHANCE = 0.66667 # 66.667% chance when the combatant's HP is at or below the barrier to endure

const _icon: Texture2D = preload('res://graphics/ui/endure.png')

@export var lowestHp: int = -1

var endured: bool = false

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0,
	i_lowestHp = -1,
):
	super(Type.ENDURE, i_potency, i_overwrites, i_turnsLeft)
	endured = false
	lowestHp = i_lowestHp

func find_attacker_idx(combatant, allCombatants: Array) -> int:
	for idx in range(len(allCombatants)):
		# if this combatant is not the afflicted, and is using a command (has already been resolved though)
		if allCombatants[idx] != combatant and allCombatants[idx].command != null and allCombatants[idx].command.commandResult != null:
			return idx
	return -1

func apply_status(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	if timing != BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		endured = false
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG and potency != Potency.NONE:
		var endureHpBarrier: int = roundi(combatant.stats.maxHp * get_min_hp_percent())
		var attackerIdx: int = find_attacker_idx(combatant, allCombatants)
		if attackerIdx != -1:
			var attacker: Combatant = allCombatants[attackerIdx]
			if attacker != null:
				var moveEffect: MoveEffect = null
				if attacker.command.type == BattleCommand.Type.MOVE and attacker.command.move != null:
					moveEffect = attacker.command.move.get_effect_of_type(attacker.command.moveEffectType)
					if attacker.command.moveEffectType == Move.MoveEffectType.SURGE:
						moveEffect = moveEffect.apply_surge_changes(absi(attacker.command.orbChange))
				if combatant.currentHp < endureHpBarrier and moveEffect != null and moveEffect.power > 0:
					if lowestHp > endureHpBarrier:
						endured = true # always endure if HP is above the barrier no matter what
					else:
						# only a chance to Endure a hit if at or below the barrier
						var combatantIdx: int = attacker.command.targets.find(combatant)
						endured = attacker.command.randomNums[combatantIdx] <= ENDURE_AT_BARRIER_CHANCE
		# if lowest HP has not been set or has been healed greater than the Endure minimum: set it
		if lowestHp == -1 or combatant.currentHp > endureHpBarrier:
			lowestHp = endureHpBarrier
		# keep the combatant's HP no lower than its lowest allowed HP
		# this will be either a certain percentage of its max HP, or
		# the lowest HP it has been at (i.e. if it gets the status while its HP is lower than this percentage)
		# the `lowestHp` value gets set to the current HP of the combatant when the combatant gets afflicted with the status, not including current damage calc (if taking dmg)
		if endured:
			combatant.currentHp = max(combatant.currentHp, min(lowestHp, endureHpBarrier), 1)
	
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants

func get_min_hp_percent() -> float:
	return MIN_PERCENT_HP_DICT[potency]

func get_status_effect_str(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and endured:
		return combatant.disp_name() + ' Endured the hit!' 
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Endure that would be defeated by a Move is instead kept alive with some HP. Only a chance once already Enduring.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Endure.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft,
		lowestHp
	)
