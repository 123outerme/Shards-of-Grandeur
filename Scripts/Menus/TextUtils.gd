class_name TextUtils

static func NumToCommaString(num: int) -> String:
	var numStr = String.num(num)
	for i in range(len(numStr) - 1, -1, -1): # for every character, going backwards:
		if (len(numStr) - 1) - i % 3 == 0: # if 3 characters have passed since the end of the string:
			numStr.insert(i, ',') # insert a comma
	
	return numStr
