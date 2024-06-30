extends StatusEffect
class_name GuardBreak

var statChangesDict: Dictionary = {
	Potency.NONE: StatChanges.new(1, 1, 1, 1, 1),
	Potency.WEAK: StatChanges.new(1, 1, 1, 0.7, 1),
	Potency.STRONG: StatChanges.new(1, 1, 1, 0.6, 1),
	Potency.OVERWHELMING: StatChanges.new(1, 1, 1, 0.5, 1),
}

const _icon: Texture2D = preload('res://graphics/ui/guard_break.png')

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0
):
	super(Type.GUARD_BREAK, i_potency, i_overwrites, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	#if timing == BattleCommand.ApplyTiming.BEFORE_DMG_CALC:
	#	combatant.statChanges.stack(statChangesDict[potency])
	#if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
	#	combatant.statChanges.stack(reverseStatChangesDict[potency])
	return super.apply_status(combatant, allCombatants, timing)

func apply_stat_change(stats: Stats) -> Stats:
	return statChangesDict[potency].apply(stats)

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Guard Break suffers a temporary debuff to their Resistance stat.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return GuardBreak.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft
	)
