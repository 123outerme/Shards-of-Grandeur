extends Resource
class_name CombatantRewards

@export var weightedRewards: Array[WeightedReward] = []

func _init(i_weightedRewards: Array[WeightedReward] = []):
	weightedRewards = i_weightedRewards
