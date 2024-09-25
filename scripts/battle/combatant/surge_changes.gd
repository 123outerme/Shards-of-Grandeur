extends Resource
class_name SurgeChanges

class SurgeChangeDescRow:
	var title: String = ''
	var description: String = ''
	
	func _init(i_title = '', i_desc = ''):
		title = i_title
		description = i_desc

@export var powerPerOrb: int = 0
@export var lifestealPerOrb: float = 0
@export var selfStatChangesPerOrb: StatChanges = StatChanges.new()
@export var targetStatChangesPerOrb: StatChanges = StatChanges.new()
@export var weakThresholdOrbs: int = 0
@export var strongThresholdOrbs: int = 0
@export var overwhelmingThresholdOrbs: int = 0
@export var additionalStatusTurnsPerOrb: float = 0
@export var additionalStatusChancePerOrb: float = 0

func _init(
	i_powerPerOrb = 0,
	i_lifestealPerOrb = 0,
	i_selfStatChangesPerOrb = StatChanges.new(),
	i_targetStatChangesPerOrb = StatChanges.new(),
	i_weakThresholdOrbs = 0,
	i_strongThresholdOrbs = 0,
	i_overwhelmingThresholdOrbs = 0,
	i_additionalStatusTurnsPerOrb = 0,
	i_additionalStatusChancePerOrb = 0,
):
	powerPerOrb = i_powerPerOrb
	lifestealPerOrb = i_lifestealPerOrb
	selfStatChangesPerOrb = i_selfStatChangesPerOrb
	targetStatChangesPerOrb = i_targetStatChangesPerOrb
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

func get_description() -> Array[SurgeChangeDescRow]:
	var descriptionLines: Array[SurgeChangeDescRow] = []
	if powerPerOrb > 0:
		
		descriptionLines.append(
			SurgeChangeDescRow.new('+ Power Per Orb:', '+' + String.num(powerPerOrb))
		)
	elif powerPerOrb < 0:
		descriptionLines.append(
			SurgeChangeDescRow.new('+ Heal Power Per Orb:', '+' + String.num(powerPerOrb * -1))
		)
	
	if lifestealPerOrb > 0:
		descriptionLines.append(
			SurgeChangeDescRow.new('+ Lifesteal % Per Orb:' ,'+' + String.num(roundi(lifestealPerOrb * 100)))
		)
	elif lifestealPerOrb < 0:
		descriptionLines.append(
			SurgeChangeDescRow.new('- Lifesteal % Per Orb:', '-' + String.num(roundi(lifestealPerOrb * -100)))
		)
		
	if selfStatChangesPerOrb != null and selfStatChangesPerOrb.has_stat_changes():
		var multipliers = selfStatChangesPerOrb.get_multipliers_text()
		descriptionLines.append(
			SurgeChangeDescRow.new('Self Boost Per Orb:', StatMultiplierText.multiplier_text_list_to_string(multipliers))
		)
	
	if targetStatChangesPerOrb != null and targetStatChangesPerOrb.has_stat_changes():
		var multipliers = targetStatChangesPerOrb.get_multipliers_text()
		descriptionLines.append(
			SurgeChangeDescRow.new('Target(s) Boost Per Orb:', StatMultiplierText.multiplier_text_list_to_string(multipliers))
		)
	
	'''
	if additionalStatusTurnsPerOrb > 0:
		descriptionLines.append(
			SurgeChangeDescRow.new('+ Status Turns Per Orb:', String.num(additionalStatusTurnsPerOrb))
		)
	'''
	
	if abs(additionalStatusChancePerOrb) > 0:
		descriptionLines.append(
			SurgeChangeDescRow.new('+ Status Chance Per Orb:', ('+' if additionalStatusChancePerOrb > 0 else '-') + String.num(abs(additionalStatusChancePerOrb) * 100))
		)
	
	if weakThresholdOrbs > 0 or strongThresholdOrbs > 0 or overwhelmingThresholdOrbs > 0:
		var thresholdDescription = ''
		var thresholds: Array[String] = []
		if weakThresholdOrbs > 0:
			thresholds.append('Weak at -' + String.num(weakThresholdOrbs) + ' Orbs')
			
		if strongThresholdOrbs > 0:
			thresholds.append('Strong at -' + String.num(strongThresholdOrbs) + ' Orbs')
			
		if overwhelmingThresholdOrbs > 0:
			thresholds.append('Overwhelming at -' + String.num(overwhelmingThresholdOrbs) + ' Orbs')
		
		for idx in range(len(thresholds)):
			thresholdDescription += thresholds[idx]
			if idx < len(thresholds) - 1:
				thresholdDescription += '\n'
		
		var header: String = 'Status Potency Threshold'
		if len(thresholds) > 1:
			header += 's'
		header += ':'
		
		descriptionLines.append(SurgeChangeDescRow.new(header, thresholdDescription))
	
	return descriptionLines
