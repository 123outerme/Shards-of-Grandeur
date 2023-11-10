extends Resource
class_name TurnQueue

@export var combatants: Array[Combatant] = []

func _init(i_combatants: Array[Combatant] = [], sort: bool = true):
	combatants = i_combatants
	if sort:
		reload()

func push(combatant: Combatant):
	combatants.append(combatant)
	reload()
		
func peek_next() -> Combatant:
	if len(combatants) == 0:
		return null
	
	return combatants.front()

func pop() -> Combatant:
	var combatant = combatants.pop_front()
	reload()
	return combatant

func empty():
	combatants = []

func reload():
	combatants = combatants.filter(filter_turns)
	combatants.sort_custom(sort_turns)
	#combatant_stable_sort()

func copy() -> TurnQueue:
	return TurnQueue.new(combatants)

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
	if a.get_exhaustion_level() < b.get_exhaustion_level():
		return true # a is less exhausted than b
	if a.get_exhaustion_level() > b.get_exhaustion_level():
		return false # a is more exhausted than b
	if a.get_manic_level() < b.get_manic_level():
		return false # b is more manic than a
	if a.get_manic_level() > b.get_manic_level():
		return true # a is more manic than b
	# otherwise, "turn priority" levels are the same
	if a.stats.speed > b.stats.speed:
		return true # a goes before b
	if a.stats.speed < b.stats.speed:
		return false # a goes after b
	# if both have equal speed:
	if b.disp_name() == PlayerResources.playerInfo.combatant.disp_name():
		return false # prefer the player go first
	return true # default: a goes before b
