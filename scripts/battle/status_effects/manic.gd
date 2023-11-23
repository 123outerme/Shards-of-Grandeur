extends StatusEffect
class_name Manic

# general idea: exhaustion affects turn order negatively, also maybe reduces resistance?

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.MANIC, i_potency, i_turnsLeft)

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	super.apply_status(combatant, timing)
	
func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND:
		return combatant.disp_name() + " is moving extremely quickly due to " + status_effect_to_string() + '!'
	return ''

func copy() -> StatusEffect:
	return Manic.new(
		potency,
		turnsLeft
	)
