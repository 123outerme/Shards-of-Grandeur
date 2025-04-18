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
	super.init_rune_state(combatant, otherCombatants, state)
	currentStatus = combatant.statusEffect

func get_rune_type() -> String:
	return 'Status Rune'

func get_long_rune_type() -> String:
	if minPotency != StatusEffect.Potency.NONE:
		return StatusEffect.potency_to_string(minPotency) + ' Status Rune'
	else:
		return get_rune_type()

func get_rune_trigger_description() -> String:
	if minPotency != StatusEffect.Potency.NONE:
		return 'When ' + StatusEffect.potency_to_string(minPotency) + ' Status is Afflicted'
	else:
		return 'When a Status is Afflicted'

func get_rune_tooltip() -> String:
	var tooltip: String = "This Rune's effect triggers when the enchanted combatant gets afflicted with a Status Effect"
	if minPotency != StatusEffect.Potency.NONE:
		tooltip += " (of at least " + StatusEffect.potency_to_string(minPotency) + " Potency)."
	return tooltip

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	return combatant.statusEffect != currentStatus and combatant.statusEffect != null and combatant.statusEffect.potency >= minPotency

func copy(copyStorage: bool = false) -> StatusRune:
	var rune: StatusRune = StatusRune.new(
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
		minPotency,
	)
	
	if copyStorage:
		rune.currentStatus = currentStatus
	
	return rune
