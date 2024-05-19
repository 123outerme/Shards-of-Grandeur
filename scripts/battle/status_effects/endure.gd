extends StatusEffect
class_name Endure

const MIN_PERCENT_HP_DICT: Dictionary = {
	Potency.NONE: 0,
	Potency.WEAK: 0.01,
	Potency.STRONG: 0.05,
	Potency.OVERWHELMING: 0.1
}

const _icon: Texture2D = preload('res://graphics/ui/endure.png')

var endured: bool = false

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.ENDURE, i_potency, i_turnsLeft)

func apply_status(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	endured = false
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG:
		if combatant.currentHp < roundi(combatant.stats.maxHp * MIN_PERCENT_HP_DICT[potency]):
			endured = true
		combatant.currentHp = max(combatant.currentHp, roundi(combatant.stats.maxHp * MIN_PERCENT_HP_DICT[potency]))
		
	dealtDmgCombatants.append_array(super.apply_status(combatant, allCombatants, timing))
	return dealtDmgCombatants

func get_status_effect_str(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC and endured:
		return combatant.disp_name() + ' Endured the hit!' 
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Endure that would be defeated by a Move is instead kept alive with some HP.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Endure.new(
		potency,
		turnsLeft
	)
