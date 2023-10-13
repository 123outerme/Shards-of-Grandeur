extends StatusEffect
class_name Exhaustion

# general idea: exhaustion affects turn order negatively, also maybe reduces resistance?

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.EXHAUSTION, i_potency, i_turnsLeft)

func apply_status(combatant: Combatant, timing: ApplyTiming):
	pass
	
func get_status_effect_str(combatant: Combatant, timing: ApplyTiming) -> String:
	return ''
