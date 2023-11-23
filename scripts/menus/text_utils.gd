class_name TextUtils

static func num_to_comma_string(num: int) -> String:
	var numStr = String.num(num)
	for i in range(len(numStr) - 4, -1, -3): # for every character, going backwards, after the last 3:
		numStr = numStr.insert(i + 1, ',') # insert a comma
	return numStr

static func substitute_playername(text: String) -> String:
	return text.replace('@', PlayerResources.playerInfo.combatant.stats.displayName)
