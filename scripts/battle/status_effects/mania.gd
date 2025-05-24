extends StatusEffect
class_name Mania

# general idea: mania affects turn order positively (increases speed)
var statChangesDict: Dictionary[Potency, StatChanges] = {
	Potency.NONE: StatChanges.new(1, 1, 1, 1, 1),
	Potency.WEAK: StatChanges.new(1, 1, 1, 1, 1.2),
	Potency.STRONG: StatChanges.new(1, 1, 1, 1, 1.4),
	Potency.OVERWHELMING: StatChanges.new(1, 1, 1, 1, 1.6),
}

const _icon: Texture2D = preload('res://graphics/ui/mania.png')

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0
):
	super(Type.MANIA, i_potency, i_overwrites, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	return super.apply_status(combatant, allCombatants, timing)

func apply_stat_change(stats: Stats) -> Stats:
	return statChangesDict[potency].apply(stats)

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND:
		var descriptor: String = 'quicker'
		match potency:
			Potency.WEAK:
				descriptor = 'quicker'
			Potency.STRONG:
				descriptor = 'much quicker'
			Potency.OVERWHELMING:
				descriptor = 'blindingly quick'
		return combatant.disp_name() + " is moving " + descriptor + " due to " + status_effect_to_string() + '!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Mania gains a temporary Speed boost when determining turn order.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Mania.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft
	)
