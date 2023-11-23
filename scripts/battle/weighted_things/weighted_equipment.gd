extends WeightedThing
class_name WeightedEquipment

@export var weapon: Weapon = null
@export var armor: Armor = null

func _init(i_weight = 0.0, i_weapon = null, i_armor = null):
	super(i_weight)
	weapon = i_weapon
	armor = i_armor
