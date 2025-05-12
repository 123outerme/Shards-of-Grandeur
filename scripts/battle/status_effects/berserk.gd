extends StatusEffect
class_name Berserk

const PERCENT_DAMAGE_DICT: Dictionary[Potency, float] = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.2,
	Potency.STRONG: 0.35,
	Potency.OVERWHELMING: 0.5
}

const _icon: Texture2D = preload('res://graphics/ui/berserk.png')

@export_storage var lastAdjustedDmg: int = 0

func _init(
	i_potency: Potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0,
	i_lastAdjustedDmg: int = 0,
):
	super(Type.BERSERK, i_potency, i_overwrites, i_turnsLeft)
	lastAdjustedDmg = i_lastAdjustedDmg

func get_recoil_damage(combatant: Combatant) -> int:
	var damage: float = 0
	# Assumption: targets are already fetched
	if combatant.command != null and combatant.command.commandResult != null:
		# calculate total damage dealt from this command
		for targetIdx in range(len(combatant.command.targets)):
			damage += max(0, combatant.command.commandResult.damagesDealt[targetIdx]) # do not go negative
		for interceptIdx in range(len(combatant.command.interceptingTargets)):
			damage += max(0, combatant.command.commandResult.damageOnInterceptingTargets[interceptIdx]) # do not go negative
		damage *= Berserk.PERCENT_DAMAGE_DICT[potency]
	return roundi(damage)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		if combatant.currentHp > 0:
			var damage: int = get_recoil_damage(combatant)
			var adjustedDmg: int = min(damage, combatant.currentHp - 1)
			combatant.currentHp = min(combatant.stats.maxHp, combatant.currentHp - adjustedDmg)
			if damage > 0:
				dealtDmgCombatants = [combatant]
				combatant.command.commandResult.selfRecoilDmg += adjustedDmg
				lastAdjustedDmg = adjustedDmg
			else:
				lastAdjustedDmg = 0
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and get_recoil_damage(combatant) > 0:
		if lastAdjustedDmg > 0:
			return combatant.disp_name() + "'s " + StatusEffect.potency_to_string(potency) \
					+ ' ' + get_status_type_string() + ' deals ' + TextUtils.num_to_comma_string(lastAdjustedDmg) + ' recoil damage!'
		else:
			return combatant.disp_name() + ' withstood ' + StatusEffect.potency_to_string(potency) \
					+ ' ' + get_status_type_string() + ' recoil!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Berserk takes recoil damage upon using a damaging move.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Berserk.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft,
		lastAdjustedDmg
	)
