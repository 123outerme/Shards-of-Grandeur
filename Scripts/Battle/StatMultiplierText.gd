class_name StatMultiplierText

var statName: String
var multiplier: float

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

func _init(i_name = '', i_multiplier = 1.0):
	statName = i_name
	multiplier = i_multiplier

func print_multiplier(useStatName: bool = true) -> String:
	var multiplierDiff: float = (multiplier - 1.0) * 100.0
	var diffSign: String = '+' if multiplierDiff >= 0 else '0'
	var multiplierText: String = ''
	if useStatName:
		multiplierText += statName + ' '
	if roundi(multiplierDiff) != 0:
		multiplierText += diffSign + TextUtils.num_to_comma_string(roundi(multiplierDiff)) + '%'
	return multiplierText
