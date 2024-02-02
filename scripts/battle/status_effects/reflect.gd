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

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	super.apply_status(combatant, timing)
	
func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	return ''

func copy() -> StatusEffect:
	return Reflect.new(
		potency,
		turnsLeft
	)
