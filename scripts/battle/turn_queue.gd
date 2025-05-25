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
	if value == null:
		return false
	if value.currentHp <= 0:
		value.command = null
		return false
	return true

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
	var aPriority: int = a.command.get_command_priority() if a.command != null else 0
	var bPriority: int = b.command.get_command_priority() if b.command != null else 0
	
	if aPriority != bPriority:
		return aPriority >= bPriority # if a's priority is greater than or equal to b, a goes first
	
	var aStats: Stats = a.stats
	if a.statusEffect != null and a.statusEffect.affects_turn_order_calc():
		aStats = a.statusEffect.apply_stat_change(aStats)
	
	var bStats: Stats = b.stats
	if b.statusEffect != null and b.statusEffect.affects_turn_order_calc():
		bStats = b.statusEffect.apply_stat_change(bStats)
	
	if aStats.speed > bStats.speed:
		return true # a goes before b
	if aStats.speed < bStats.speed:
		return false # a goes after b
	# if both have equal speed:
	if b.save_name() == PlayerResources.playerInfo.combatant.save_name():
		return false # prefer the player go first
	return true # default: a goes before b
