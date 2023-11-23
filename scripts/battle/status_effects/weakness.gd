extends StatusEffect
class_name Weakness

var statChangesDict: Dictionary = {
	Potency.NONE: StatChanges.new(0.8, 1, 1, 1, 1),
	Potency.WEAK: StatChanges.new(0.7, 1, 1, 1, 1),
	Potency.STRONG: StatChanges.new(0.6, 1, 1, 1, 1),
	Potency.OVERWHELMING: StatChanges.new(0.5, 1, 1, 1, 1),
}

var reverseStatChangesDict: Dictionary = {
	Potency.NONE: StatChanges.new(1.2, 1, 1, 1, 1),
	Potency.WEAK: StatChanges.new(1.3, 1, 1, 1, 1),
	Potency.STRONG: StatChanges.new(1.4, 1, 1, 1, 1),
	Potency.OVERWHELMING: StatChanges.new(1.5, 1, 1, 1, 1),
}

func _init(
	i_potency = Potency.NONE,
	i_turnsLeft = 0
):
	super(Type.WEAKNESS, i_potency, i_turnsLeft)

func apply_status(combatant: Combatant, timing: BattleCommand.ApplyTiming):
	if timing == BattleCommand.ApplyTiming.BEFORE_DMG_CALC:
		combatant.statChanges.stack(statChangesDict[potency])
	if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
		combatant.statChanges.stack(reverseStatChangesDict[potency])
	super.apply_status(combatant, timing)
	
func get_status_effect_str(combatant: Combatant, timing: BattleCommand.ApplyTiming) -> String:
	return ''

func copy() -> StatusEffect:
	return Weakness.new(
		potency,
		turnsLeft
	)
