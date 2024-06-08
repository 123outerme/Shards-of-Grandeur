extends StatusEffect
class_name Mania

# general idea: mania affects turn order positively, also maybe increases resistance?

const _icon: Texture2D = preload('res://graphics/ui/mania.png')

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0
):
	super(Type.MANIA, i_potency, i_overwrites, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	return super.apply_status(combatant, allCombatants, timing)
	
func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND:
		return combatant.disp_name() + " is moving extremely quickly due to " + status_effect_to_string() + '!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Mania moves first in a turn, before all combatants without Mania.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Mania.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft
	)
