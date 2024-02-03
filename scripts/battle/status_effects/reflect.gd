extends StatusEffect
class_name Reflect

const PERCENT_DAMAGE_DICT: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.13,
	Potency.STRONG: 0.19,
	Potency.OVERWHELMING: 0.25
} # percentage of incoming damage reflected to attacker

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.REFLECT, i_potency, i_turnsLeft)

func get_recoil_damage(target: Combatant, combatant: Combatant) -> int:
	var damage: int = 0
	# Assumption: targets are already fetched
	if target.command != null:
		damage += combatant.command.calculate_damage(target, combatant)
	
	return roundi(damage * Reflect.PERCENT_DAMAGE_DICT[potency])

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		for target in combatant.command.targets:
			target.currentHp = max(target.currentHp - get_recoil_damage(target, combatant), 1) # recoil can never knock you out!
	super.apply_status(combatant, timing)
	
func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	return ''

func copy() -> StatusEffect:
	return Reflect.new(
		potency,
		turnsLeft
	)
