extends StatusEffect
class_name Weakness

var statChangesDict: Dictionary[Potency, StatChanges] = {
	Potency.NONE: StatChanges.new(1, 1, 1, 1, 1),
	Potency.WEAK: StatChanges.new(0.7, 1, 1, 1, 1),
	Potency.STRONG: StatChanges.new(0.6, 1, 1, 1, 1),
	Potency.OVERWHELMING: StatChanges.new(0.5, 1, 1, 1, 1),
}

const _icon: Texture2D = preload('res://graphics/ui/weakness.png')

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0
):
	super(Type.WEAKNESS, i_potency, i_overwrites, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	#if timing == BattleCommand.ApplyTiming.BEFORE_DMG_CALC:
#		combatant.statChanges.stack(statChangesDict[potency])
	#if timing == BattleCommand.ApplyTiming.AFTER_DMG_CALC:
	#	combatant.statChanges.stack(reverseStatChangesDict[potency])
	return super.apply_status(combatant, allCombatants, timing)

func apply_stat_change(stats: Stats) -> Stats:
	return statChangesDict[potency].apply(stats)

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Weakness suffers a temporary debuff to their Physical attack damage.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Weakness.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft
	)
