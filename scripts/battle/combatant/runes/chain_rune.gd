extends Rune
class_name ChainRune

func get_rune_type() -> String:
	return 'Chain Rune'

func get_rune_trigger_description() -> String:
	return 'When Another Rune Triggers'

func get_rune_tooltip() -> String:
	return "This Rune's effect is triggered when another Rune that's placed on the enchanted combatant gets triggered."

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	return len(combatant.triggeredRunes) > 0

func copy(copyStorage: bool = false) -> ChainRune:
	return ChainRune.new(
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
		triggerAnims,
	)
