class_name TextUtils

static func num_to_comma_string(num: int) -> String:
	var numStr = String.num(abs(num)) # just get the digits
	for i in range(len(numStr) - 4, -1, -3): # for every character, going backwards, after the last 3:
		numStr = numStr.insert(i + 1, ',') # insert a comma
	if num < 0:
		numStr = '-' + numStr # add a negative sign in front if it was negative
	return numStr

static func rich_text_substitute(text: String, iconSize: Vector2i) -> String:
	var output: String = substitute_playername(text)
	output = substitute_icons(output, iconSize)
	output = substitute_textcolors(output)
	return output

static func substitute_icons(text: String, iconSize: Vector2i) -> String:
	var output = text.replace('$orb', '[img=' + String.num(iconSize.x) + 'x' + String.num(iconSize.y) + ']res://graphics/ui/orb_filled.png[/img]')
	return output

static func substitute_textcolors(text: String) -> String:
	var output = text.replace('$highlight{', '[color=#E3781A]') # red #FF5A52, orange #d58035 or #D2830C or #E3781A, blue #2A9ED9
	output = output.replace('}color$', '[/color]')
	return output

static func substitute_playername(text: String) -> String:
	return text.replace('@', PlayerResources.playerInfo.combatant.stats.displayName)

static func escape_user_input(text: String) -> String:
	return text.replace('[', '[lb]')

static func get_elapsed_time(secs: float) -> String:
	var temp: float = secs
	var mins: int = floori(temp / 60.0) % 60
	temp /= 60.0
	var hours: int = floori(temp / 60.0)
	secs = floori(secs) % 60
	
	return String.num(hours) + 'h ' + String.num(mins) + 'm ' + String.num(secs) + 's'

static func string_arr_to_string(strings: Array[String], twoSeparator: String = ' and ', middleSeparator: String = ', ', finalSeparator: String = ', and ', prefix: String = '', suffix: String = '') -> String:
	var finalString: String = ''
	for idx: int in range(len(strings)):
		finalString += prefix + strings[idx] + suffix
		if idx < len(strings) - 1:
			if idx < len(strings) - 2:
				finalString += middleSeparator
			elif len(strings) == 2:
				finalString += twoSeparator
			else:
				finalString += finalSeparator
	
	return finalString
