extends Rune
class_name BoostRune

@export_storage var prevStatChanges: StatChanges = null

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
	i_prevStatChanges: StatChanges = null,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	prevStatChanges = i_prevStatChanges

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	prevStatChanges = combatant.statChanges

func get_rune_type() -> String:
	return 'Boost Rune'

func get_rune_trigger_description() -> String:
	return 'When Stat Boosts Are Applied'

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming) -> bool:
	return combatant.statChanges != prevStatChanges

func copy(copyStorage: bool = false) -> BoostRune:
	var rune: BoostRune = BoostRune.new(
		orbChange,
		category,
		element,
		power,
		lifesteal,
		statChanges.duplicate() if statChanges != null else null,
		statusEffect.duplicate() if statusEffect != null else null,
		surgeChanges.duplicate() if surgeChanges != null else null,
		caster if copyStorage else null,
		runeSpriteAnim,
		triggerAnim,
	)
	
	if copyStorage:
		rune.prevStatChanges = prevStatChanges
	
	return rune
