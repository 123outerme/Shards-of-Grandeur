extends Resource
class_name MoveEffect

enum Role {
	OTHER = 0, ## Other
	SINGLE_TARGET_DAMAGE = 1, ## Single-target damage
	AOE_DAMAGE = 2, ## AoE (multi-target) damage
	BUFF = 3, ## Buff
	DEBUFF = 4, ## Debuff
	HEAL = 5, ## Healing
	SETUP = 6, ## Setup
}
## move role (for use in auto-learning moves)
@export var role: Role = Role.OTHER

## list of keywords this MoveEffect is included in
@export var keywords: Array[String] = []

## negative is minimum orb surge, positive is orb charge
@export_range(-10, 10) var orbChange: int = 0

## negative power is healing, positive power is damage
@export_range(-100, 100) var power: int = 0 

## <= 0 is no lifesteal, otherwise a percentage of all final damage (including intercepted damage)
@export var lifesteal: float = 0

## <= is no self-HP sacrificate, otherwise a percentage of max HP to lose when using the move
@export var selfHpSacrifice: float = 0

## Speed priority of move; higher priority moves go before lower priority moves
@export_range(-3, 3) var priority: int = 0

## who this move can target
@export var targets: BattleCommand.Targets = BattleCommand.Targets.SELF

## how this move changes user's stats
@export var selfStatChanges: StatChanges = StatChanges.new()

## how this move changes its targets's stats (not including interceptors)
@export var targetStatChanges: StatChanges = StatChanges.new()

## the status effect this move will inflict
@export var statusEffect: StatusEffect = null

## if false, target gets status. If true, gives it to user
@export var selfGetsStatus: bool = false

## Base percentage chance to apply status. 0% is auto-fail, 100% is auto-pass
@export var statusChance: float = 0.0

## if true, target stat changes will not occur unless status effect is applied
@export var statusRequiredForTargetStatChanges: bool = false

## the Rune to set up when the move hits
@export var rune: Rune = null

## how the surge effect changes when an additional orb is added
@export var surgeChanges: SurgeChanges = null

static func role_to_string(r: Role) -> String:
	match r:
		Role.OTHER:
			return 'Other'
		Role.SINGLE_TARGET_DAMAGE:
			return 'Single Target'
		Role.AOE_DAMAGE:
			return 'AOE'
		Role.BUFF:
			return 'Buff'
		Role.DEBUFF:
			return 'Debuff'
		Role.HEAL:
			return 'Heal'
		Role.SETUP:
			return 'Setup'
	return 'UNKOWN'

func _init(
	i_role: Role = Role.OTHER,
	i_keywords: Array[String] = [],
	i_power: int = 0,
	i_orbChange: int = 0,
	i_lifesteal: float = 0.0,
	i_selfHpSacrifice: float = 0.0,
	i_targets: BattleCommand.Targets = BattleCommand.Targets.SELF,
	i_selfStatChanges: StatChanges = StatChanges.new(),
	i_targetStatChanges: StatChanges = StatChanges.new(),
	i_statusEffect: StatusEffect = null,
	i_selfGetsStatus: bool = false,
	i_statusChance: float = 0.0,
	i_statusRequiredForTargetStatChanges: bool = false,
	i_rune: Rune = null,
	i_surgeChanges: SurgeChanges = null,
):
	role = i_role
	keywords = i_keywords
	power = i_power
	orbChange = i_orbChange
	lifesteal = i_lifesteal
	selfHpSacrifice = i_selfHpSacrifice
	targets = i_targets
	selfStatChanges = i_selfStatChanges
	targetStatChanges = i_targetStatChanges
	statusEffect = i_statusEffect
	selfGetsStatus = i_selfGetsStatus
	statusChance = i_statusChance
	statusRequiredForTargetStatChanges = i_statusRequiredForTargetStatChanges
	rune = i_rune
	surgeChanges = i_surgeChanges

func get_short_description(dmgCategory: Move.DmgCategory = Move.DmgCategory.PHYSICAL, moveElement: Move.Element = Move.Element.NONE) -> Array[String]:
	var effects: Array[String] = []
	
	if orbChange > 0:
		effects.append('+' + String.num_int64(orbChange) + ' $orb')
	
	if power > 0:
		var powerString: String = String.num_int64(power)
		if moveElement != Move.Element.NONE:
			powerString += ' ' + Move.element_to_string(moveElement)
		powerString += ' ' + Move.dmg_category_to_string(dmgCategory) + ' Power'
		effects.append(powerString)
	elif power < 0:
		effects.append(String.num_int64(power * -1) + ' Heal Power')
	
	if selfHpSacrifice > 0:
		effects.append('-' + String.num_int64(roundi(selfHpSacrifice * 100)) + '% Self HP')
	
	if lifesteal > 0:
		effects.append(String.num_int64(roundi(lifesteal * 100)) + '% Lifesteal')
	
	if selfStatChanges != null and selfStatChanges.has_stat_changes():
		var multiplierTexts: Array[StatMultiplierText] = selfStatChanges.get_multipliers_text()
		effects.append('Self: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if targetStatChanges != null and targetStatChanges.has_stat_changes():
		var multiplierTexts: Array[StatMultiplierText] = targetStatChanges.get_multipliers_text()
		effects.append('Target: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if statusEffect != null:
		var accuracyString: String = String.num_int64(roundi(statusChance * 100)) + ' Chance'
		if statusChance >= 1:
			accuracyString = 'Guaranteed'
		var statusString: String = StatusEffect.potency_to_string(statusEffect.potency) \
			+ ' ' + statusEffect.get_status_type_string() \
			+ ' (' + accuracyString + ')'
		if statusEffect.overwritesOtherStatuses:
			statusString += ', Replaces'
		effects.append(statusString)
	
	if rune != null:
		if orbChange >= 0:
			effects.append('+ ' + rune.get_rune_type())
		else:
			effects.append('+ Surged ' + rune.get_rune_type())
	
	return effects

'''
func get_changes_description(spendingOrbs: int) -> Array[String]:
	var changedSurgeEff: MoveEffect = apply_surge_changes(spendingOrbs)
	var effects: Array[String] = []
	
	if abs(changedSurgeEff.power) > abs(power):
		if changedSurgeEff.power > 0:
			effects.append(String.num_int64(changedSurgeEff.power) + ' Power')
		elif changedSurgeEff.power < 0:
			effects.append(String.num_int64(changedSurgeEff.power * -1) + ' Heal Power')
	
	if changedSurgeEff.lifesteal > lifesteal:
		effects.append(String.num_int64(roundi(changedSurgeEff.lifesteal * 100)) + '% Lifesteal')
	
	if changedSurgeEff.selfStatChanges != null and not changedSurgeEff.selfStatChanges.equals(selfStatChanges):
		var diffs: StatChanges = changedSurgeEff.selfStatChanges.subtract(selfStatChanges)
		var multiplierTexts: Array[StatMultiplierText] = diffs.get_multipliers_text()
		if len(multiplierTexts) > 0:
			effects.append('Self: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if changedSurgeEff.targetStatChanges != null and not changedSurgeEff.targetStatChanges.equals(targetStatChanges):
		var diffs: StatChanges = changedSurgeEff.targetStatChanges.subtract(targetStatChanges)
		var multiplierTexts: Array[StatMultiplierText] = diffs.get_multipliers_text()
		if len(multiplierTexts) > 0:
			effects.append('Target: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if changedSurgeEff.statusEffect != null and (changedSurgeEff.statusChance > statusChance or \
			changedSurgeEff.statusEffect.potency != statusEffect.potency):
		var accuracyString: String = String.num_int64(roundi(changedSurgeEff.statusChance * 100)) + ' Chance'
		if changedSurgeEff.statusChance >= 1:
			accuracyString = 'Guaranteed'
		effects.append(
			StatusEffect.potency_to_string(changedSurgeEff.statusEffect.potency) \
			+ ' ' + changedSurgeEff.statusEffect.get_status_type_string() \
			+ ' (' + accuracyString + ')'
		)
	
	if changedSurgeEff.rune != null and changedSurgeEff.rune.surgeChanges != null:
		effects.append('+ Surged ' + changedSurgeEff.rune.get_rune_type())
	
	return effects
'''

func apply_surge_changes(orbsSpent: int) -> MoveEffect:
	if surgeChanges == null:
		return self
	
	var additionalOrbs: int = orbsSpent - (orbChange * -1)
	var newEffect = copy()
	
	newEffect.power += surgeChanges.powerPerOrb * additionalOrbs
	
	newEffect.lifesteal = max(0, newEffect.lifesteal + surgeChanges.lifestealPerOrb * additionalOrbs)
	
	# NOTE: should max self HP sacrifice be 100%? 99%? 95%?
	newEffect.selfHpSacrifice = min(1, max(0, newEffect.selfHpSacrifice + surgeChanges.selfHpSacrificePerOrb * additionalOrbs))
	
	var finalSelfStatChanges: StatChanges = surgeChanges.selfStatChangesPerOrb.duplicate(true) if surgeChanges.selfStatChangesPerOrb else StatChanges.new()
	finalSelfStatChanges.times(additionalOrbs)
	if newEffect.selfStatChanges == null:
		newEffect.selfStatChanges = StatChanges.new()
	newEffect.selfStatChanges.stack(finalSelfStatChanges)
	
	var finalTargetStatChanges: StatChanges = surgeChanges.targetStatChangesPerOrb.duplicate(true) if surgeChanges.targetStatChangesPerOrb else StatChanges.new()
	finalTargetStatChanges.times(additionalOrbs)
	if newEffect.targetStatChanges == null:
		newEffect.targetStatChanges = StatChanges.new()
	newEffect.targetStatChanges.stack(finalTargetStatChanges)
	
	# new status chance is the greater of the old status chance or the surge's status chance, + additional chance / orb, capped at 100%
	newEffect.statusChance = min(1, newEffect.statusChance + surgeChanges.get_additional_status_chance(additionalOrbs))
	
	if newEffect.statusEffect != null:
		if surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs) != StatusEffect.Potency.NONE:
			newEffect.statusEffect.potency = surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs)
		newEffect.statusEffect.turnsLeft += surgeChanges.get_additional_status_turns(additionalOrbs)
	
	if newEffect.rune != null:
		newEffect.rune = newEffect.rune.apply_surge_changes(additionalOrbs)
	
	return newEffect
	
func copy() -> MoveEffect:
	var newEffect: MoveEffect = MoveEffect.new(
		role,
		keywords,
		power,
		orbChange,
		lifesteal,
		selfHpSacrifice,
		targets,
		selfStatChanges.copy() if selfStatChanges != null else null,
		targetStatChanges.copy() if targetStatChanges != null else null,
		statusEffect.copy() if statusEffect != null else null,
		selfGetsStatus,
		statusChance,
		statusRequiredForTargetStatChanges,
		rune.copy() if rune != null else null,
		surgeChanges
	)
	return newEffect
