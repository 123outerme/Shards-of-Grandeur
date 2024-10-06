extends Resource
class_name PreterminedAllocation

# this class represents one "section" of the predetermined stat point allocation strategy
# For the number of stat points defined by `forStatPoints`, this "section" will be referenced
# For each category defined in the `allocations` strategy, one stat point will be allocated
# if forStatPoints == n * len(allocations), this process is repeated n times
# `n` must be an integer always

## length of this array must be a multiple of `forStatPoints`
@export var allocations: Array[Stats.Category] = []

## this number must be divisible by the length of the `allocations` array
@export var forStatPoints: int = 1

func _init(i_allocations: Array[Stats.Category] = [], i_forStatPoints: int = 1):
	allocations = i_allocations
	forStatPoints = i_forStatPoints
