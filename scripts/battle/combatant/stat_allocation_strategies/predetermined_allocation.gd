extends Resource
class_name PreterminedAllocation

## length of this array must be a multiple of `forStatPoints`
@export var allocations: Array[Stats.Category] = []
## this number must be divisible by the length of the `allocations` array
@export var forStatPoints: int = 1

func _init(i_allocations: Array[Stats.Category] = [], i_forStatPoints: int = 1):
	allocations = i_allocations
	forStatPoints = i_forStatPoints
