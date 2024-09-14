extends StatusEffect
class_name Reflect

const PERCENT_DAMAGE_DICT: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.35,
	Potency.STRONG: 0.55,
	Potency.OVERWHELMING: 0.70
} # percentage of incoming damage reflected to attacker

const _icon: Texture2D = preload('res://graphics/ui/reflect.png')

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0
):
	super(Type.REFLECT, i_potency, i_overwrites, i_turnsLeft)

func get_recoil_damage(combatant, allCombatants: Array, attackerIdx: int) -> int:
	var damage: int = 0
	if allCombatants[attackerIdx].command == null or allCombatants[attackerIdx].command.commandResult == null:
		printerr('Reflect error: ', attackerIdx, ' / ', allCombatants[attackerIdx].disp_name(), ' did not have a command ongoing')
		return damage
	# Assumption: targets are already fetched
	# if the afflicted combatant is in the list of targets, add up damage dealt to the afflicted to reflect back to the attacker
	for targetIdx in range(len(allCombatants[attackerIdx].command.targets)):
		if combatant == allCombatants[attackerIdx].command.targets[targetIdx] and allCombatants[attackerIdx].command.commandResult != null:
			damage += max(0, allCombatants[attackerIdx].command.commandResult.damagesDealt[targetIdx]) # do not go negative
	for interceptIdx in range(len(allCombatants[attackerIdx].command.interceptingTargets)):
		if combatant in allCombatants[attackerIdx].command.interceptingTargets and allCombatants[attackerIdx].command.commandResult != null:
			damage += max(0, allCombatants[attackerIdx].command.commandResult.damageOnInterceptingTargets[interceptIdx]) # do not go negative
	damage *= Reflect.PERCENT_DAMAGE_DICT[potency]
	allCombatants[attackerIdx].command.commandResult.selfRecoilDmg += damage
	return roundi(damage)

func find_attacker_idx(combatant, allCombatants: Array) -> int:
	for idx in range(len(allCombatants)):
		# if this combatant is not the afflicted, and is using a command (has already been resolved though)
		if allCombatants[idx] != combatant and allCombatants[idx].command != null:
			return idx
	return -1

func apply_status(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG:
		var attackerIdx = find_attacker_idx(combatant, allCombatants)
		if attackerIdx > -1:
			var recoilDmg = get_recoil_damage(combatant, allCombatants, attackerIdx)
			allCombatants[attackerIdx].currentHp = max(allCombatants[attackerIdx].currentHp - recoilDmg, 0) # recoil can never knock you out!
			# if the combatant damage is reflected to is Enduring, apply the status again to ensure the Endure is applied appropriately
			if allCombatants[attackerIdx].statusEffect != null and allCombatants[attackerIdx].statusEffect.type == Type.ENDURE:
				allCombatants[attackerIdx].statusEffect.apply_status(combatant, allCombatants, timing)
			if recoilDmg > 0:
				dealtDmgCombatants = [allCombatants[attackerIdx]]
		else:
			printerr('Reflect error: timing ', timing, ' on combatant ', combatant.disp_name(), ' no attacker found?')
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants
	
func get_status_effect_str(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and get_recoil_damage(combatant, allCombatants, find_attacker_idx(combatant, allCombatants)) > 0:
		var attackerIdx = find_attacker_idx(combatant, allCombatants)
		return combatant.disp_name() + "'s " + StatusEffect.potency_to_string(potency) \
				+ ' ' + get_status_type_string() + ' deals ' + TextUtils.num_to_comma_string(get_recoil_damage(combatant, allCombatants, attackerIdx)) + ' damage back to ' + allCombatants[attackerIdx].disp_name() + '!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Reflect deals recoil to any attackers, as a percentage of damage taken.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Reflect.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft
	)
