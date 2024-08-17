extends Resource
class_name ElementMultiplier

@export var element: Move.Element = Move.Element.NONE
@export var multiplier: float = 1.0

func _init(
	i_element = Move.Element.NONE,
	i_multiplier = 1.0,
):
	element = i_element
	multiplier = i_multiplier
