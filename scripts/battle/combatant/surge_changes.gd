extends Resource
class_name SurgeChanges

@export var powerPerOrb: int = 0
@export var selfStatChangesPerOrb: StatChanges = StatChanges.new()
@export var targetStatChangesPerOrb: StatChanges = StatChanges.new()
@export var additionalStatusEffect: StatusEffect = null
@export var statusBaseChance: float = 0
@export var weakThresholdOrbs: int = 0
@export var strongThresholdOrbs: int = 0
@export var overwhelmingThresholdOrbs: int = 0
@export var additionalStatusTurnsPerOrb: float = 0
@export var additionalStatusChancePerOrb: float = 0

func _init(
	i_powerPerOrb = 0,
	i_selfStatChangesPerOrb = StatChanges.new(),
	i_targetStatChangesPerOrb = StatChanges.new(),
	i_additionalStatusEffect = null,
	i_statusBaseChance = 0,
	i_weakThresholdOrbs = 0,
	i_strongThresholdOrbs = 0,
	i_overwhelmingThresholdOrbs = 0,
	i_additionalStatusTurnsPerOrb = 0,
	i_additionalStatusChancePerOrb = 0,
):
	powerPerOrb = i_powerPerOrb
	selfStatChangesPerOrb = i_selfStatChangesPerOrb
	targetStatChangesPerOrb = i_targetStatChangesPerOrb
	additionalStatusEffect = i_additionalStatusEffect
	statusBaseChance = i_statusBaseChance
	weakThresholdOrbs = i_weakThresholdOrbs
	strongThresholdOrbs = i_strongThresholdOrbs
	overwhelmingThresholdOrbs = i_overwhelmingThresholdOrbs
	additionalStatusTurnsPerOrb = i_additionalStatusTurnsPerOrb
	additionalStatusChancePerOrb = i_additionalStatusChancePerOrb

func get_potency_for_additional_orbs_spent(additionalSpent: int) -> StatusEffect.Potency:
	if additionalSpent >= overwhelmingThresholdOrbs:
		return StatusEffect.Potency.OVERWHELMING
	if additionalSpent >= strongThresholdOrbs:
		return StatusEffect.Potency.STRONG
	if additionalSpent >= weakThresholdOrbs:
		return StatusEffect.Potency.WEAK
	return StatusEffect.Potency.NONE

func get_additional_status_turns(additionalSpent: int) -> int:
	return roundi(additionalSpent * additionalStatusTurnsPerOrb)

func get_additional_status_chance(additionalSpent: int) -> float:
	return roundi(additionalSpent * additionalStatusChancePerOrb)

func get_description() -> String:
	var descriptionLines: Array[String] = []
	if powerPerOrb > 0:
		descriptionLines.append('+' + String.num(powerPerOrb) + ' Additional Power / Orb')
	elif powerPerOrb < 0:
		descriptionLines.append('+' + String.num(powerPerOrb * -1) + ' Additional Heal Power / Orb')
		
	if selfStatChangesPerOrb != null and selfStatChangesPerOrb.has_stat_changes():
		var multipliers = selfStatChangesPerOrb.get_multipliers_text()
		descriptionLines.append('Self Boosts / Orb: ' + StatMultiplierText.multiplier_text_list_to_string(multipliers))
	
	if targetStatChangesPerOrb != null and targetStatChangesPerOrb.has_stat_changes():
		var multipliers = targetStatChangesPerOrb.get_multipliers_text()
		descriptionLines.append('Target(s) Boost / Orb: ' + StatMultiplierText.multiplier_text_list_to_string(multipliers))
	
	if additionalStatusEffect != null:
		descriptionLines.append('Applies ' + StatusEffect.potency_to_string(additionalStatusEffect.potency) \
				+ ' ' + StatusEffect.status_type_to_string(additionalStatusEffect.type) \
				+ '(' + String.num(roundi(statusBaseChance * 100)) + '% Chance)')
		
	if weakThresholdOrbs > 0 or strongThresholdOrbs > 0 or overwhelmingThresholdOrbs > 0:
		var thresholdDescription = 'Status Potency:'
		var thresholds: Array[String] = []
		if weakThresholdOrbs > 0:
			thresholds.append('Weak at ' + String.num(weakThresholdOrbs) + ' Orbs')
			
		if weakThresholdOrbs > 0:
			thresholds.append('Strong at ' + String.num(weakThresholdOrbs) + ' Orbs')
			
		if weakThresholdOrbs > 0:
			thresholds.append('Overwhelming at ' + String.num(weakThresholdOrbs) + ' Orbs')
		
		for idx in range(len(thresholds)):
			thresholdDescription += thresholds[idx]
			if idx < len(thresholds) - 1:
				thresholdDescription += ', '
		
		descriptionLines.append(thresholdDescription)
	
	if additionalStatusTurnsPerOrb > 0:
		descriptionLines.append('Additional Status Turns / Orb: ' + String.num(additionalStatusTurnsPerOrb))
	
	if additionalStatusChancePerOrb > 0:
		descriptionLines.append('Additional Status Chance / Orb: ' + String.num(additionalStatusChancePerOrb * 100) + '%')
	
	var description: String = ''
	for lineIdx in range(len(descriptionLines)):
		description += descriptionLines[lineIdx]
		if lineIdx < len(descriptionLines) - 1:
			description += '\n'
	return description
