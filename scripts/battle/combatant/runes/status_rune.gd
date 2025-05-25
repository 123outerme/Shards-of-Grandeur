extends Rune
class_name StatusRune

## minimum Potency of status required to trigger
@export var minPotency: StatusEffect.Potency = StatusEffect.Potency.WEAK

## if not NONE, will only trigger off of the specified status
@export var type: StatusEffect.Type = StatusEffect.Type.NONE

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
	i_type: StatusEffect.Type = StatusEffect.Type.NONE,
	i_currentStatus: StatusEffect = null,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	minPotency = i_minPotency
	type = i_type
	currentStatus = i_currentStatus

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	super.init_rune_state(combatant, otherCombatants, state)
	currentStatus = combatant.statusEffect

func get_rune_type() -> String:
	return 'Status Rune'

func get_long_rune_type() -> String:
	var statusName: String = 'Status'
	if type != StatusEffect.Type.NONE:
		statusName = StatusEffect.status_type_to_string(type)
	if minPotency != StatusEffect.Potency.NONE:
		return StatusEffect.potency_to_string(minPotency) + ' ' + statusName + ' Rune'
	else:
		return statusName + ' Rune'

func get_rune_trigger_description() -> String:
	var statusName: String = 'Status'
	if type != StatusEffect.Type.NONE:
		statusName = StatusEffect.status_type_to_string(type)
	if minPotency != StatusEffect.Potency.NONE:
		return 'When ' + StatusEffect.potency_to_string(minPotency) + ' ' + statusName + ' is Afflicted'
	else:
		return 'When Any ' + statusName + ' is Afflicted'

func get_rune_tooltip() -> String:
	var tooltip: String = "This Rune's effect triggers when the enchanted combatant gets afflicted with a Status Effect"
	if minPotency != StatusEffect.Potency.NONE:
		tooltip += " (of at least " + StatusEffect.potency_to_string(minPotency) + " Potency)."
	return tooltip

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	if combatant.statusEffect == null:
		return false
	
	var statusTypeMatches: bool = false
	if type != StatusEffect.Type.NONE:
		statusTypeMatches = type == combatant.statusEffect.type
	else:
		statusTypeMatches = true
	
	return combatant.statusEffect != currentStatus and combatant.statusEffect.potency >= minPotency and statusTypeMatches

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
		type,
	)
	
	if copyStorage:
		rune.currentStatus = currentStatus
	
	return rune
