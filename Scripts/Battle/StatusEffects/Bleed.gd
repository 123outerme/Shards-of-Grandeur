extends StatusEffect
class_name Bleed

var percentDamageDict: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.04,
	Potency.STRONG: 0.07,
	Potency.OVERWHELMING: 0.1
}

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0,
):
	super(Type.BLEED, i_potency, i_turnsLeft)

func get_bleed_damage(combatant: Combatant) -> int:
	return roundi(combatant.stats.maxHp * percentDamageDict[potency])

func apply_status(combatant: Combatant, timing: ApplyTiming):
	if timing == ApplyTiming.AFTER_ROUND:
		combatant.currentHp = max(combatant.currentHp - get_bleed_damage(combatant), 0)
	
func get_status_effect_str(combatant: Combatant, timing: ApplyTiming) -> String:
	if timing == ApplyTiming.AFTER_ROUND:
		return combatant.disp_name() + "'s " + StatusEffect.potency_to_string(potency) \
				+ ' ' + StatusEffect.status_type_to_string(type) + ' deals ' + str(get_bleed_damage(combatant)) + ' bleed damage!'
	return ''
