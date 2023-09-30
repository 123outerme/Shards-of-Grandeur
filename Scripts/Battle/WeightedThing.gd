extends Resource
class_name WeightedThing

@export var weight: float = 0.0

static func pick_item(weights: Array[WeightedThing]):
	var accumulator: float = 0
	var randomNum: float = randf()
	for i in range(len(weights)):
		accumulator += weights[i].weight
		if randomNum <= accumulator:
			return i
	return len(weights) - 1

func _init(i_weight = 0.0):
	weight = i_weight
