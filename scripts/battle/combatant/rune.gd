extends Resource
class_name Rune

@export_category('Effect')

## orbs gained for caster
@export_range(0, 10) var orbChange: int = 0

## damage category for the power of the rune
@export var category: Move.DmgCategory = Move.DmgCategory.PHYSICAL

## elemental type for the power of the rune
@export var element: Move.Element = Move.Element.NONE

## power of an attack aimed at the enchanted combatant. Negative power is healing, positive power is damage
@export_range(-100, 100) var power: int = 0

## lifesteal on dealt damage for the caster. <= 0 is no lifesteal, otherwise a percentage of all final damage (including intercepted damage) back to the inflictor
@export var lifesteal: float = 0

## how this rune changes the enchanted combatant's stats
@export var statChanges: StatChanges = StatChanges.new()

## the status effect this rune will afflict
@export var statusEffect: StatusEffect = null

## the surge changes (except status chance and self Stat Changes) that will be applied to the rune
@export var surgeChanges: SurgeChanges = null

@export_storage var caster: Combatant = null

@export_category('Visuals')
## the animation to play while the rune is applied to the combatant
@export var runeSpriteAnim: MoveAnimSprite = null

## the animation to play when the rune is triggered
@export var triggerAnim: MoveAnimSprite = null

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
):
	orbChange = i_orbChange
	category = i_category
	element = i_element
	power = i_power
	lifesteal = i_lifesteal
	statChanges = i_statChanges
	statusEffect = i_statusEffect
	surgeChanges = i_surgeChanges
	caster = i_caster
	runeSpriteAnim = i_runeSpriteAnim
	triggerAnim = i_triggerAnim

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	if len(otherCombatants) > 0:
		caster = otherCombatants[0]
	else:
		printerr('Rune init_rune_state() error: caster not provided')

func get_rune_type() -> String:
	return 'ERROR DEFAULT RUNE' # implement in ALL subclasses

func get_rune_trigger_description() -> String:
	return 'ERROR DEFAULT RUNE' # implement in ALL subclasses

func get_rune_tooltip() -> String:
	return 'ERROR DEFAULT RUNE' # implement in ALL subclasses

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	return false # implement in subclasses

func apply_surge_changes(additionalOrbs: int) -> Rune:
	var rune: Rune = copy()
	if surgeChanges == null:
		return rune
	
	rune.power += surgeChanges.powerPerOrb * additionalOrbs
	rune.lifesteal += surgeChanges.lifestealPerOrb * additionalOrbs
	var finalStatChanges: StatChanges = surgeChanges.targetStatChangesPerOrb.duplicate(true) if surgeChanges.targetStatChangesPerOrb != null else StatChanges.new()
	finalStatChanges.times(additionalOrbs)
	rune.statChanges = rune.statChanges.stack(finalStatChanges)
	
	if rune.statusEffect != null:
		if surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs) != StatusEffect.Potency.NONE:
			rune.statusEffect.potency = surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs)
		rune.statusEffect.turnsLeft += surgeChanges.get_additional_status_turns(additionalOrbs)
	
	return rune

func copy(copyStorage: bool = false) -> Rune:
	return Rune.new(
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
	)
