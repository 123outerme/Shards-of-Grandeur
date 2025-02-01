extends Resource
class_name WeightedThing

@export var weight: float = 0.0

static func pick_item(weights: Array, sumWeights: float = 1.0) -> int:
	if len(weights) > 0 and (not (weights[0] is WeightedThing) or sumWeights == 0):
		print("WeightedThing warning: array is not properly formed")
		return -1
		
	var accumulator: float = 0
	var randomNum: float = randf_range(0, sumWeights)
	for i in range(len(weights)):
		accumulator += weights[i].weight
		if randomNum <= accumulator:
			return i
	return len(weights) - 1

func _init(i_weight = 0.0):
	weight = i_weight
