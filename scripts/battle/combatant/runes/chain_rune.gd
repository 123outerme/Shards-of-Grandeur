extends Rune
class_name ChainRune

@export_storage var runeTriggered: bool = false

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
	i_triggered: bool = false,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	runeTriggered = i_triggered

func get_rune_trigger_description() -> String:
	return 'When Another Rune Triggers'

func get_rune_type() -> String:
	return 'Chain Rune'

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming) -> bool:
	return runeTriggered

func copy(copyStorage: bool = false) -> ChainRune:
	var rune: ChainRune = ChainRune.new(orbChange, category, element, power, lifesteal, statChanges.duplicate(), statusEffect.duplicate(), surgeChanges.duplicate(), caster if copyStorage else null, runeSpriteAnim, triggerAnim)
	
	if copyStorage:
		rune.runeTriggered = runeTriggered
	
	return rune
