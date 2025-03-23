extends WeightedThing
class_name WeightedEquipment

@export var weapon: Weapon = null
@export var armor: Armor = null
@export var accessory: Accessory = null

func _init(i_weight = 0.0, i_weapon = null, i_armor = null, i_accessory: Accessory = null):
	super(i_weight)
	weapon = i_weapon
	armor = i_armor
	accessory = i_accessory
