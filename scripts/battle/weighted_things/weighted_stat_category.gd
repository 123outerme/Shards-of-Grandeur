extends WeightedThing
class_name WeightedStatCategory

@export var category: Stats.Category = Stats.Category.PHYS_ATK

func _init(i_weight = 0, i_category = Stats.Category.PHYS_ATK):
    super._init(i_weight)
    category = i_category
