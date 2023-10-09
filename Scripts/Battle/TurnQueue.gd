extends Resource
class_name TurnQueue

@export var combatants: Array[Combatant] = []

func _init(i_combatants: Array[Combatant] = []):
	combatants = i_combatants
	reload()

func push(combatant: Combatant):
	combatants.append(combatant)
	reload()
		
func peek_next() -> Combatant:
	#reload()
	if len(combatants) == 0:
		return null
	
	return combatants.front()

func pop() -> Combatant:
	#reload()
	var combatant = combatants.pop_front()
	reload()
	return combatant

func reload():
	combatants = combatants.filter(filter_turns)
	combatants.sort_custom(sort_turns)
	#combatant_stable_sort()

func filter_turns(value: Combatant) -> bool:
	return value != null and value.currentHp > 0

'''
func combatant_stable_sort(): # insertion sort - there will never be more than 5 items in this queue so I don't care
	for i in range(1, len(combatants)):
		var c = combatants[i]
		var j: int = i - 1
		while j >= 0 and sort_turns(combatants[i], combatants[j]) <= 0: 
			combatants[j + 1] = combatants[j]
			j -= 1
		combatants[j + 1] = c
'''

func sort_turns(a: Combatant, b: Combatant) -> bool:
	if a.stats.speed > b.stats.speed:
		return true # a goes before b
	if a.stats.speed < b.stats.speed:
		return false # a goes after b
	return true # default: a goes before b
