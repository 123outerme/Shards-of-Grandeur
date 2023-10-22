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

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		combatant.currentHp = max(combatant.currentHp - get_bleed_damage(combatant), 0)
	
func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		return combatant.disp_name() + ' takes ' + str(get_bleed_damage(combatant)) + ' bleed damage from ' + status_effect_to_string() + '!'
	return ''

func copy() -> StatusEffect:
	return Bleed.new(
		potency,
		turnsLeft
	)
