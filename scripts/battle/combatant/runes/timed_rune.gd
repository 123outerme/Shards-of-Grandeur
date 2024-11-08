extends Rune
class_name TimedRune

## the number of turns after the rune is put in place until it triggers (first turn being counted at the end step of the same turn)
@export var afterTurns: int = 1

@export_storage var turnCounter: int = 0

func _init(
	i_orbChange: int = 0,
	i_category: Move.DmgCategory = Move.DmgCategory.PHYSICAL,
	i_element: Move.Element = Move.Element.NONE,
	i_power: int = 0,
	i_lifesteal: float = 0,
	i_statChanges: StatChanges = null,
	i_statusEffect: StatusEffect = null,
	i_surgeChanges: SurgeChanges = null,
	i_caster: Combatant = null,
	i_runeSpriteAnim: MoveAnimSprite = null,
	i_triggerAnim: MoveAnimSprite = null,
	i_afterTurns: int = 1,
	i_turnCounter: int = 0,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	afterTurns = i_afterTurns
	turnCounter = i_turnCounter

func get_rune_type() -> String:
	return 'Timed Rune'

func get_rune_trigger_description() -> String:
	return 'After ' + String.num(afterTurns - turnCounter) + ' Turns'

func get_rune_tooltip() -> String:
	return "This Rune's effect triggers after " + String.num(afterTurns) + ' have passed.'

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming) -> bool:
	if timing == BattleCommand.ApplyTiming.AFTER_ROUND:
		turnCounter += 1
	return turnCounter >= afterTurns

func copy(copyStorage: bool = false) -> TimedRune:
	var rune: TimedRune = TimedRune.new(
		orbChange,
		category,
		element,
		power,
		lifesteal,
		statChanges.copy() if statChanges != null else null,
		statusEffect.duplicate() if statusEffect != null else null,
		surgeChanges.duplicate() if surgeChanges != null else null,
		caster if copyStorage else null,
		runeSpriteAnim,
		triggerAnim,
		afterTurns,
	)
	
	if copyStorage:
		rune.turnCounter = turnCounter
	
	return rune
