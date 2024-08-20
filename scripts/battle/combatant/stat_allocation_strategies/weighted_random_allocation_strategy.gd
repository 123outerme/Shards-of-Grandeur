extends StatAllocationStrategy
class_name WeightedRandomAllocationStrategy

@export var categories: Array[WeightedStatCategory] = []

func _init(i_categories: Array[WeightedStatCategory] = []):
	super._init()
	categories = i_categories.duplicate(true)

func allocate_stats(stats: Stats, allocateAmount: int = -1):
	if len(categories) == 0:
		return

	var stopAt: int = max(stats.statPts - allocateAmount, 0)
	if allocateAmount <= -1:
		stopAt = 0

	while stats.statPts > stopAt:
		var categoryIdx: int = WeightedThing.pick_item(categories)
		if categoryIdx == -1:
			return
		allocate_stat(stats, categories[categoryIdx].category)
