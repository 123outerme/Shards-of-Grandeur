extends Resource
class_name CombatantEquipment

@export var weightedEquipment: Array[WeightedEquipment] = []

func _init(
	i_weightedEquipment: Array[WeightedEquipment] = [],
):
	weightedEquipment = i_weightedEquipment
