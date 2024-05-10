extends Resource
class_name EnemyEncounter

@export var combatant1: Combatant = null

func _init(i_combatant1 = null):
	combatant1 = i_combatant1
