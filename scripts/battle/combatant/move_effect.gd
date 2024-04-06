extends Resource
class_name MoveEffect

enum Role {
	OTHER = 0,
	SINGLE_TARGET_DAMAGE = 1,
	AOE_DAMAGE = 2,
	BUFF = 3,
	DEBUFF = 4,
	HEAL = 5
}

@export var role: Role = Role.OTHER
@export_range(-10, 10) var orbChange: int = 0 # negative is orb surge, positive is orb charge
@export_range(-100, 100) var power: int = 0 # negative power is healing, positive power is damage
@export var targets: BattleCommand.Targets = BattleCommand.Targets.SELF
@export var selfStatChanges: StatChanges = StatChanges.new()
@export var targetStatChanges: StatChanges = StatChanges.new()
@export var statusEffect: StatusEffect = null
@export var selfGetsStatus: bool = false # if false, target gets status. If true, give it self
@export var statusChance: float = 0.0
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
	return 'UNKOWN'

func _init(
	i_role = Role.OTHER,
	i_power = 0,
	i_orbChange = 0,
	i_targets = BattleCommand.Targets.SELF,
	i_selfStatChanges = StatChanges.new(),
	i_targetStatChanges = StatChanges.new(),
	i_statusEffect = null,
	i_selfGetsStatus = false,
	i_statusChance = 0.0,
	i_surgeChanges = null,
):
	role = i_role
	power = i_power
	orbChange = i_orbChange
	targets = i_targets
	selfStatChanges = i_selfStatChanges
	targetStatChanges = i_targetStatChanges
	statusEffect = i_statusEffect
	selfGetsStatus = i_selfGetsStatus
	statusChance = i_statusChance
	surgeChanges = i_surgeChanges

func get_short_description() -> Array[String]:
	var effects: Array[String] = []
	
	if orbChange > 0:
		effects.append('+' + String.num(orbChange) + ' Orbs')
	
	if power > 0:
		effects.append(String.num(power) + ' Power')
	elif power < 0:
		effects.append(String.num(power * -1) + ' Heal Power')
	
	if selfStatChanges.has_stat_changes():
		var multiplierTexts: Array[StatMultiplierText] = selfStatChanges.get_multipliers_text()
		effects.append('Self: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if targetStatChanges.has_stat_changes():
		var multiplierTexts: Array[StatMultiplierText] = targetStatChanges.get_multipliers_text()
		effects.append('Target: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if statusEffect != null:
		effects.append(
			StatusEffect.potency_to_string(statusEffect.potency) \
			+ ' ' + StatusEffect.status_type_to_string(statusEffect.type) \
			+ ' (' + String.num(roundi(statusChance * 100)) + '%)'
		)
	
	return effects

func get_changes_description(spendingOrbs: int) -> Array[String]:
	var changedSurgeEff: MoveEffect = apply_surge_changes(spendingOrbs)
	var effects: Array[String] = []
	
	if abs(changedSurgeEff.power) > abs(power):
		if changedSurgeEff.power > 0:
			effects.append(String.num(changedSurgeEff.power) + ' Power')
		elif changedSurgeEff.power < 0:
			effects.append(String.num(changedSurgeEff.power * -1) + ' Heal Power')
	
	if not changedSurgeEff.selfStatChanges.equals(selfStatChanges):
		var diffs: StatChanges = changedSurgeEff.selfStatChanges.subtract(selfStatChanges)
		var multiplierTexts: Array[StatMultiplierText] = diffs.get_multipliers_text()
		effects.append('Self: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if not changedSurgeEff.targetStatChanges.equals(targetStatChanges):
		var diffs: StatChanges = changedSurgeEff.targetStatChanges.subtract(targetStatChanges)
		var multiplierTexts: Array[StatMultiplierText] = diffs.get_multipliers_text()
		effects.append('Target: ' + StatMultiplierText.multiplier_text_list_to_string(multiplierTexts))
	
	if changedSurgeEff.statusEffect != null and (changedSurgeEff.statusChance > statusChance or \
			changedSurgeEff.statusEffect.potency != statusEffect.potency):
		effects.append(
			StatusEffect.potency_to_string(changedSurgeEff.statusEffect.potency) \
			+ ' ' + StatusEffect.status_type_to_string(changedSurgeEff.statusEffect.type) \
			+ ' (' + String.num(roundi(changedSurgeEff.statusChance * 100)) + '%)'
		)
	
	return effects

func apply_surge_changes(orbsSpent: int) -> MoveEffect:
	if surgeChanges == null:
		return self
	
	var additionalOrbs: int = orbsSpent - (orbChange * -1)
	var newEffect = copy()
	
	newEffect.power += surgeChanges.powerPerOrb * additionalOrbs
	
	var finalSelfStatChanges: StatChanges = surgeChanges.selfStatChangesPerOrb.duplicate() if surgeChanges.selfStatChangesPerOrb else StatChanges.new()
	finalSelfStatChanges.times(additionalOrbs)
	if newEffect.selfStatChanges == null:
		newEffect.selfStatChanges = StatChanges.new()
	newEffect.selfStatChanges.stack(finalSelfStatChanges)
	
	var finalTargetStatChanges: StatChanges = surgeChanges.targetStatChangesPerOrb.duplicate() if surgeChanges.targetStatChangesPerOrb else StatChanges.new()
	finalTargetStatChanges.times(additionalOrbs)
	if newEffect.targetStatChanges == null:
		newEffect.targetStatChanges = StatChanges.new()
	newEffect.targetStatChanges.stack(finalTargetStatChanges)
	
	# new status chance is the greater of the old status chance or the surge's status chance, + additional chance / orb, capped at 100%
	newEffect.statusChance = min(1, max(newEffect.statusChance, surgeChanges.statusBaseChance) + surgeChanges.get_additional_status_chance(additionalOrbs))
	
	if newEffect.statusEffect != null:
		if surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs) != StatusEffect.Potency.NONE:
			newEffect.statusEffect.potency = surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs)
		newEffect.statusEffect.turnsLeft += surgeChanges.get_additional_status_turns(additionalOrbs)
	
	return newEffect
	
func copy() -> MoveEffect:
	var newEffect: MoveEffect = MoveEffect.new(
		role,
		power,
		orbChange,
		targets,
		selfStatChanges.duplicate() if selfStatChanges != null else null,
		targetStatChanges.duplicate() if targetStatChanges != null else null,
		statusEffect,
		selfGetsStatus,
		statusChance,
		surgeChanges
	)
	return newEffect
