extends StatusEffect
class_name Berserk

const PERCENT_DAMAGE_DICT: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.05,
	Potency.STRONG: 0.1,
	Potency.OVERWHELMING: 0.15
}

func _init(
	i_potency: Potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.BERSERK, i_potency, i_turnsLeft)

func get_recoil_damage(combatant: Combatant) -> int:
	var damage: int = 0
	# Assumption: targets are already fetched
	if combatant.command != null:
		for target in combatant.command.targets:
			damage += combatant.command.calculate_damage(combatant, target, -1)
	
	return roundi(damage * Berserk.PERCENT_DAMAGE_DICT[potency])

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		combatant.currentHp = max(combatant.currentHp - get_recoil_damage(combatant), 1) # recoil can never knock you out!
	super.apply_status(combatant, timing)

func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and get_recoil_damage(combatant) > 0:
		return combatant.disp_name() + "'s " + StatusEffect.potency_to_string(potency) \
				+ ' ' + StatusEffect.status_type_to_string(type) + ' deals ' + str(get_recoil_damage(combatant)) + ' recoil damage!'
	return ''

func copy() -> StatusEffect:
	return Berserk.new(
		potency,
		turnsLeft
	)
