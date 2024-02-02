extends StatusEffect
class_name Interception

# battle code will handle intercepting combatants' attacks

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.INTERCEPTION, i_potency, i_turnsLeft)

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	super.apply_status(combatant, timing)
	
func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	return ''

func copy() -> StatusEffect:
	return Interception.new(
		potency,
		turnsLeft
	)
