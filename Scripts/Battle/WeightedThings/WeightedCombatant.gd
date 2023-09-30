extends WeightedThing
class_name WeightedCombatant

@export var combatant: Combatant = null

func _init(i_weight = 0.0, i_combatant = null):
	super(i_weight)
	combatant = i_combatant
