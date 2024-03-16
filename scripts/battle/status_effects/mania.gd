extends StatusEffect
class_name Mania

# general idea: mania affects turn order positively, also maybe increases resistance?

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.MANIA, i_potency, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	return super.apply_status(combatant, allCombatants, timing)
	
func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND:
		return combatant.disp_name() + " is moving extremely quickly due to " + status_effect_to_string() + '!'
	return ''

func copy() -> StatusEffect:
	return Mania.new(
		potency,
		turnsLeft
	)
