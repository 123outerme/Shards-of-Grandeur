extends StatusEffect
class_name Berserk

var percentDamageDict: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 5.0,
	Potency.STRONG: 10.0,
	Potency.OVERWHELMING: 15.0
}

func _init(
	i_potency: Potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.BERSERK, i_potency, i_turnsLeft)

func get_recoil_damage(combatant: Combatant) -> int:
	var damage: int = 0
	# Assumption: targets are already fetched
	for target in combatant.command.targets:
		damage += combatant.command.calculate_damage(combatant, target)
	
	return roundi(damage * percentDamageDict[potency])

func apply_status(combatant: Combatant, timing: ApplyTiming):
	if timing == ApplyTiming.AFTER_DMG_CALC and get_recoil_damage(combatant) > 0:
		combatant.currentHp = max(combatant.currentHp - get_recoil_damage(combatant), 1) # recoil can never knock you out!
	super.apply_status(combatant, timing)

func get_status_effect_str(combatant: Combatant, timing: ApplyTiming) -> String:
	if timing == ApplyTiming.AFTER_DMG_CALC:
		return combatant.disp_name() + "'s " + StatusEffect.potency_to_string(potency) \
				+ ' ' + StatusEffect.status_type_to_string(type) + ' deals ' + str(get_recoil_damage(combatant)) + ' recoil damage!'
	return ''
