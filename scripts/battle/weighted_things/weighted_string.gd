extends WeightedThing
class_name WeightedString

@export var string: String = ''

func _init(i_weight = 0.0, i_str = ''):
	super(i_weight)
	string = i_str
