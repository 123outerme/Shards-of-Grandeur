extends Resource
class_name TurnQueue

@export var combatants: Array[Combatant] = []

func _init(i_combatants: Array[Combatant] = []):
	combatants = i_combatants

func push(combatant: Combatant):
	combatants.append(combatant)
		
func peek_next() -> Combatant:
	reload()
	return combatants.front()

func pop() -> Combatant:
	reload()
	return combatants.pop_front()

func reload():
	combatants = combatants.filter(filter_turns)
	combatants.sort_custom(sort_turns)

func filter_turns(value: Combatant) -> bool:
	return value.currentHp > 0

func sort_turns(a: Combatant, b: Combatant) -> bool:
	if a.stats.speed <= b.stats.speed:
		return true # b moves after a
	return false # a moves after b
