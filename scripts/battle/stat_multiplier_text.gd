class_name StatMultiplierText

var statName: String
var increase: int = 0
var multiplier: float = 1.0

static func multiplier_text_list_to_string(multiplierTexts: Array[StatMultiplierText]) -> String:
	var multipliersStr = ''
	for idx in range(len(multiplierTexts)):
		multipliersStr += multiplierTexts[idx].print_multiplier()
		if idx < len(multiplierTexts) - 1:
			if len(multiplierTexts) > 2:
				multipliersStr += ','
			if idx == len(multiplierTexts) - 2:
				multipliersStr += ' and'
			multipliersStr += ' '
	return multipliersStr

func _init(i_name = '', i_increase = 0, i_multiplier = 1.0):
	statName = i_name
	increase = i_increase
	multiplier = i_multiplier

func print_multiplier(useStatName: bool = true) -> String:
	var multiplierDiff: float = (multiplier - 1.0) * 100.0
	var multDiffSign: String = '+' if multiplierDiff >= 0 else '' # minus sign is included in building str
	var increaseDiffSign: String = '+' if increase >= 0 else ''
	var multiplierText: String = ''
	if useStatName:
		multiplierText += statName + ' '
	if increase != 0:
		multiplierText += increaseDiffSign + TextUtils.num_to_comma_string(increase) + ' pt'
		if abs(increase) > 1:
			multiplierText += 's'
	if roundi(multiplierDiff) != 0:
		if increase != 0:
			multiplierText += ', '
		multiplierText += multDiffSign + TextUtils.num_to_comma_string(roundi(multiplierDiff)) + '%'
	return multiplierText

func has_changes() -> bool:
	return increase != 0 or multiplier != 1.0

func equals(other: StatMultiplierText) -> bool:
	return statName == other.statName and increase == other.increase and multiplier == other.multiplier
	
