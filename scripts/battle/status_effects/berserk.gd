extends StatusEffect
class_name Berserk

const PERCENT_DAMAGE_DICT: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.25,
	Potency.STRONG: 0.4,
	Potency.OVERWHELMING: 0.55
}

func _init(
	i_potency: Potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.BERSERK, i_potency, i_turnsLeft)

func get_recoil_damage(combatant: Combatant) -> int:
	var damage: int = 0
	# Assumption: targets are already fetched
	if combatant.command != null and combatant.command.commandResult != null:
		# calculate total damage dealt from this command
		for targetIdx in range(len(combatant.command.targets)):
			damage += combatant.command.commandResult.damagesDealt[targetIdx]
		for interceptIdx in range(len(combatant.command.interceptingTargets)):
			damage += combatant.command.commandResult.damageOnInterceptingTargets[interceptIdx]
	
	return roundi(damage * Berserk.PERCENT_DAMAGE_DICT[potency])

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		if combatant.currentHp > 0:
			combatant.currentHp = max(combatant.currentHp - get_recoil_damage(combatant), 1) # recoil can never knock you out!
			if get_recoil_damage(combatant) > 0:
				dealtDmgCombatants = [combatant]
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and get_recoil_damage(combatant) > 0:
		return combatant.disp_name() + "'s " + StatusEffect.potency_to_string(potency) \
				+ ' ' + StatusEffect.status_type_to_string(type) + ' deals ' + String.num(get_recoil_damage(combatant)) + ' recoil damage!'
	return ''

func copy() -> StatusEffect:
	return Berserk.new(
		potency,
		turnsLeft
	)
