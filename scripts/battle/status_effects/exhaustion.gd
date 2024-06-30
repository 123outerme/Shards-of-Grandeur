extends StatusEffect
class_name Exhaustion

# general idea: exhaustion affects turn order negatively (reduces speed)
var statChangesDict: Dictionary = {
	Potency.NONE: StatChanges.new(1, 1, 1, 1, 1),
	Potency.WEAK: StatChanges.new(1, 1, 1, 1, 0.8),
	Potency.STRONG: StatChanges.new(1, 1, 1, 1, 0.6),
	Potency.OVERWHELMING: StatChanges.new(1, 1, 1, 1, 0.4),
}

const _icon: Texture2D = preload('res://graphics/ui/exhaustion.png')

func _init(
	i_potency = Potency.NONE,
	i_overwrites = false,
	i_turnsLeft = 0
):
	super(Type.EXHAUSTION, i_potency, i_overwrites, i_turnsLeft)

func apply_status(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> Array[Combatant]:
	return super.apply_status(combatant, allCombatants, timing)

func apply_stat_change(stats: Stats) -> Stats:
	return statChangesDict[potency].apply(stats)

func get_status_effect_str(combatant: Combatant, allCombatants: Array[Combatant], timing: BattleCommand.ApplyTiming) -> String:
	if timing == BattleCommand.ApplyTiming.BEFORE_ROUND:
		return combatant.disp_name() + " can't keep up due to " + status_effect_to_string() + '!'
	return ''

func get_status_effect_tooltip():
	return 'A combatant with Exhaustion suffers a temporary Speed decrease when determining turn order.'

func get_icon() -> Texture2D:
	return _icon

func copy() -> StatusEffect:
	return Exhaustion.new(
		potency,
		overwritesOtherStatuses,
		turnsLeft
	)
