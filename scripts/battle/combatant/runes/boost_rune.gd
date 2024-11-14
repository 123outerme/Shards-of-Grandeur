extends Rune
class_name BoostRune

@export var triggerCategory: Stats.Category = Stats.Category.NONE

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
	i_triggerCategory: Stats.Category = Stats.Category.NONE,
	i_prevStatChanges: StatChanges = null,
):
	super(i_orbChange, i_category, i_element, i_power, i_lifesteal, i_statChanges, i_statusEffect, i_surgeChanges, i_caster, i_runeSpriteAnim, i_triggerAnim)
	triggerCategory = i_triggerCategory
	prevStatChanges = i_prevStatChanges

func init_rune_state(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState) -> void:
	super.init_rune_state(combatant, otherCombatants, state)
	prevStatChanges = combatant.statChanges.copy()

func get_rune_type() -> String:
	return 'Boost Rune'

func get_long_rune_type() -> String:
	if does_trigger_on_any_category():
		return get_rune_type()
	var statString: String = Stats.category_to_string(triggerCategory)
	if triggerCategory == Stats.Category.PHYS_ATK:
		statString = 'Physical'
	if triggerCategory == Stats.Category.MAGIC_ATK:
		statString = 'Magic'
	return statString  + ' Boost Rune'

func get_rune_trigger_description() -> String:
	if does_trigger_on_any_category():
		return 'When Stat Boosts Are Applied'
	return 'When ' + Stats.category_to_string(triggerCategory) + ' Boosts Are Applied'

func get_rune_tooltip() -> String:
	var statString: String = ''
	if not does_trigger_on_any_category():
		statString = Stats.category_to_string(triggerCategory) + ' '
	return "This Rune's effect triggers when the enchanted combatant's " + statString + 'Stat Boosts change.'

func does_rune_trigger(combatant: Combatant, otherCombatants: Array[Combatant], state: BattleState, timing: BattleCommand.ApplyTiming, firstCheck: bool) -> bool:
	if prevStatChanges == null and combatant.statChanges != null:
		if does_trigger_on_any_category():
			return true
		# if the previous stat changes don't have any changes, and this one has changes: it triggers
		var multiplierText: StatMultiplierText = combatant.statChanges.get_multiplier_for_stat_category(triggerCategory)
		if multiplierText.has_changes():
			return true
	
	if prevStatChanges != null and combatant.statChanges == null:
		if does_trigger_on_any_category():
			return true
		var multiplierText: StatMultiplierText = prevStatChanges.get_multiplier_for_stat_category(triggerCategory)
		if multiplierText.has_changes():
			return true

	if does_trigger_on_any_category():
		if not prevStatChanges.equals(combatant.statChanges):
			return true
	else:
		var prevMultiplierText: StatMultiplierText = prevStatChanges.get_multiplier_for_stat_category(triggerCategory)
		var currentMultiplierText: StatMultiplierText = combatant.statChanges.get_multiplier_for_stat_category(triggerCategory)
		if not prevMultiplierText.equals(currentMultiplierText):
			return true
	
	# is this necessary? this might just be a no-op after the first time copying over, assuming rune state isn't init'd (which it should be)
	prevStatChanges = combatant.statChanges.copy()
	
	return false

func does_trigger_on_any_category() -> bool:
	return triggerCategory == Stats.Category.NONE or triggerCategory == Stats.Category.HP

func copy(copyStorage: bool = false) -> BoostRune:
	var rune: BoostRune = BoostRune.new(
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
		triggerCategory
	)
	
	if copyStorage:
		rune.prevStatChanges = prevStatChanges
	
	return rune
