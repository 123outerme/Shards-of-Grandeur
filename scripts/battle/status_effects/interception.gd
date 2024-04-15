extends StatusEffect
class_name Interception

const PERCENT_DAMAGE_DICT: Dictionary = {
	Potency.NONE: 0.0,
	Potency.WEAK: 0.15,
	Potency.STRONG: 0.25,
	Potency.OVERWHELMING: 0.35
}

const _icon: Texture2D = preload('res://graphics/ui/exhaustion.png')

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.INTERCEPTION, i_potency, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	return super.apply_status(combatant, allCombatants, timing)
	
func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Interception redirects some damage away from allies.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Interception.new(
		potency,
		turnsLeft
	)
