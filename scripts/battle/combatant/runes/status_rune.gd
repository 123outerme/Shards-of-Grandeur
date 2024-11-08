extends Rune
class_name StatusRune

## minimum Potency of status required to trigger
@export var minPotency: StatusEffect.Potency = StatusEffect.Potency.WEAK

@export_storage var currentStatus: StatusEffect = null

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
	i_minPotency: StatusEffect.Potency = StatusEffect.Potency.WEAK,
	i_currentStatus: StatusEffect = null,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	minPotency = i_minPotency
	currentStatus = i_currentStatus

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	currentStatus = combatant.statusEffect

func get_rune_type() -> String:
	return 'Status Rune'

func get_rune_trigger_description() -> String:
	return 'When Status is Afflicted'

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming) -> bool:
	return combatant.statusEffect != currentStatus and combatant.statusEffect != null and combatant.statusEffect.potency >= minPotency

func copy(copyStorage: bool = false) -> StatusRune:
	var rune: StatusRune = StatusRune.new(orbChange, category, element, power, lifesteal, statChanges.duplicate(), statusEffect.duplicate(), surgeChanges.duplicate(), caster if copyStorage else null, runeSpriteAnim, triggerAnim, minPotency)
	
	if copyStorage:
		rune.currentStatus = currentStatus
	
	return rune
