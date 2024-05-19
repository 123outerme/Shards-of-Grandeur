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
var lowestHp: int = -1

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.ENDURE, i_potency, i_turnsLeft)
	endured = false
	lowestHp = -1

func apply_status(combatant, allCombatants: Array, timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	if timing != BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		endured = false
	var dealtDmgCombatants: Array[Combatant] = []
	if timing == BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG:
		if combatant.currentHp < roundi(combatant.stats.maxHp * MIN_PERCENT_HP_DICT[potency]):
			endured = true
		# if lowest HP has not been set or has been healed greater than the Endure minimum: set it
		if lowestHp == -1 or combatant.currentHp > roundi(combatant.stats.maxHp * MIN_PERCENT_HP_DICT[potency]):
			lowestHp = roundi(combatant.stats.maxHp * MIN_PERCENT_HP_DICT[potency])
		# keep the combatant's HP no lower than its lowest allowed HP
		# this will be either a certain percentage of its max HP, or
		# the lowest HP it has been at (i.e. if it gets the status while its HP is lower than this percentage)
		# the `lowestHp` value gets set to the current HP of the combatant when the combatant gets afflicted with the status, not including current damage calc (if taking dmg)
		combatant.currentHp = max(combatant.currentHp, min(lowestHp, roundi(combatant.stats.maxHp * MIN_PERCENT_HP_DICT[potency])))
		
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
