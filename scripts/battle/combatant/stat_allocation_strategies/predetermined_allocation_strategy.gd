extends StatAllocationStrategy
class_name PredeterminedAllocationStrategy

# see the PreterminedAllocation script for a full explanation on how each allocation should be defined
# when more stat points need to be allocated than the total summed up in each allocation of `allocations`,
# The process is repeated started at the first allocation again

## must have length > 0
@export var allocations: Array[PreterminedAllocation] = []

func _init(i_allocations: Array[PreterminedAllocation] = []):
	super._init()
	allocations = i_allocations.duplicate(true)

func allocate_stats(stats: Stats, allocateAmount: int = -1):
	if not are_allocations_defined_valid():
		printerr('PredeterminedAllocationStrategy allocate_stats() error: Allocations are not defined valid. Bailing out.')
		return

	var totalStatPts: int = stats.get_total_gained_stat_points()
	var spentStatPts: int = totalStatPts - stats.statPts

	var statPtsAccum: int = 0
	var allocationIdx: int = -1

	# loop the defined allocations after the end of the array (so that allocations can continue infinitely, starting at the strategy for stat point #1 again)
	while allocationIdx == -1:
		for idx in range(len(allocations)):
			statPtsAccum += allocations[idx].forStatPoints
			if spentStatPts <= statPtsAccum:
				allocationIdx = idx
				break
		# if there are no stat points accumulated, then 
		if statPtsAccum == 0:
			return

	var stopAt: int = max(stats.statPts - allocateAmount, 0)
	if allocateAmount <= -1:
		stopAt = 0

	while stats.statPts > stopAt:
		var allocation: PreterminedAllocation = allocations[allocationIdx]
		var numAllocationLoops: int = allocation.forStatPoints / len(allocation.allocations)
		
		# Calc the IDX, like, for example:
		# with 2 allocation strat items, both of stat pts length 3: 5/5 stat points remaining -> idx 0, 4/5 -> 1, 3/5 -> 2, then 2/5 -> the next item idx 0, 1/5 that item idx 1, etc.
		var categoryIdx: int = (totalStatPts - stats.statPts) - (statPtsAccum - allocation.forStatPoints)
		if categoryIdx >= numAllocationLoops * len(allocation.allocations):
			allocationIdx = (allocationIdx + 1) % len(allocations)
			statPtsAccum += allocations[allocationIdx].forStatPoints
			continue
		# if length of the array is not equal to the forStatPoints amount, then bring it within the bounds of the array
		categoryIdx = categoryIdx % len(allocation.allocations)
		allocate_stat(stats, allocation.allocations[categoryIdx])

func are_allocations_defined_valid() -> bool:
	# if no allocations at all: invalid
	if len(allocations) == 0:
		return false

	for allocation in allocations:
		# if no categories in this allocation, no stat points for which this allocation should be applied, or too many categories for the number of stat points to properly cover:
		if allocation == null or len(allocation.allocations) == 0 or allocation.forStatPoints <= 0 \
				or len(allocation.allocations) > allocation.forStatPoints or allocation.forStatPoints % len(allocation.allocations) != 0:
			return false

	return true
